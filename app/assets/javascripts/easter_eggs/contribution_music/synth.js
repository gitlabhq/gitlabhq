import { BRIGHT_DECAY, GATE, RELEASE } from './constants';

const MASTER_GAIN = 0.7;
const ECHO_SECONDS = 0.3;
const ECHO_FEEDBACK = 0.3;
const ECHO_MIX = 0.18;
const ECHO_DAMP_HZ = 3200;
const ECHO_RUMBLE_HZ = 220;
const SILENCE = 0.0001;
const LOOKAHEAD_MS = 25;
const SCHEDULE_AHEAD_SECONDS = 0.12;
const LEAD_IN_SECONDS = 0.1;
const FADE_SECONDS = 0.05;
const ANALYSER_FFT_SIZE = 256;
const ANALYSER_SMOOTHING = 0.8;

export const midiToFrequency = (midi) => 440 * 2 ** ((midi - 69) / 12);

export const isAudioSupported = () => Boolean(window.AudioContext || window.webkitAudioContext);

const loudness = (frequency) => {
  if (frequency < 330) {
    return Math.min(2.2, (330 / frequency) ** 0.45);
  }

  return frequency > 1400 ? (1400 / frequency) ** 0.12 : 1;
};

const softClipCurve = () => {
  const samples = 1024;

  return Float32Array.from({ length: samples }, (_, index) => {
    const x = (index / (samples - 1)) * 2 - 1;

    return (x * (27 + x * x)) / (27 + 9 * x * x);
  });
};

export const createPlayer = ({
  onColumn,
  onPosition,
  onEnd,
  connectOutput = (context, node) => node.connect(context.destination),
}) => {
  let context = null;
  let master = null;
  let analyser = null;
  let spectrum = null;
  let bus = null;
  let timer = null;
  let frame = null;

  let columns = [];
  let secondsPerColumn = 1 / 6;
  let shouldLoop = true;

  let nextColumn = 0;
  let queue = [];
  let startedAt = 0;
  let runSeconds = 0;

  const buildChain = () => {
    master = context.createGain();
    master.gain.value = MASTER_GAIN;

    const shaper = context.createWaveShaper();
    shaper.curve = softClipCurve();

    const delay = context.createDelay(1);
    delay.delayTime.value = ECHO_SECONDS;
    const rumble = context.createBiquadFilter();
    rumble.type = 'highpass';
    rumble.frequency.value = ECHO_RUMBLE_HZ;
    const damp = context.createBiquadFilter();
    damp.type = 'lowpass';
    damp.frequency.value = ECHO_DAMP_HZ;
    const feedback = context.createGain();
    feedback.gain.value = ECHO_FEEDBACK;
    const wet = context.createGain();
    wet.gain.value = ECHO_MIX;

    master.connect(shaper);
    master.connect(delay);
    delay.connect(rumble).connect(damp).connect(feedback).connect(delay);
    delay.connect(wet).connect(shaper);
    connectOutput(context, shaper);

    analyser = context.createAnalyser();
    analyser.fftSize = ANALYSER_FFT_SIZE;
    analyser.smoothingTimeConstant = ANALYSER_SMOOTHING;
    spectrum = new Uint8Array(analyser.frequencyBinCount);
    shaper.connect(analyser);
  };

  const playNote = ({ frequency, voice, columnGain = 1, startTime, columnSeconds }) => {
    const filter = context.createBiquadFilter();
    filter.type = 'lowpass';
    filter.frequency.value = voice.cutoff;
    filter.Q.value = 0.7;

    const envelope = context.createGain();
    const peak = voice.gain * loudness(frequency) * columnGain;
    const peakTime = startTime + voice.attack;

    const endTime = voice.sustain
      ? startTime + columnSeconds * (GATE + RELEASE)
      : peakTime + voice.decay;

    envelope.gain.setValueAtTime(SILENCE, startTime);
    envelope.gain.linearRampToValueAtTime(peak, peakTime);

    if (voice.sustain) {
      envelope.gain.setValueAtTime(peak, Math.max(peakTime, startTime + columnSeconds * GATE));
    }

    envelope.gain.exponentialRampToValueAtTime(SILENCE, endTime);
    filter.connect(envelope).connect(bus);

    const parts = [{ wave: voice.wave, ratio: 1, detune: 0, gain: 1 }];

    if (voice.partial) {
      parts.push({ ratio: 1, detune: 0, gain: 1, ...voice.partial });
    }

    parts.forEach((part) => {
      const oscillator = context.createOscillator();
      oscillator.type = part.wave;
      oscillator.frequency.value = frequency * part.ratio;
      oscillator.detune.value = part.detune;

      const level = context.createGain();
      level.gain.setValueAtTime(part.gain, startTime);

      if (part.bright) {
        level.gain.exponentialRampToValueAtTime(
          SILENCE,
          startTime + voice.attack + voice.decay * BRIGHT_DECAY,
        );
      }

      oscillator.connect(level).connect(filter);
      oscillator.start(startTime);
      oscillator.stop(endTime);
    });
  };

  const timeOf = (index) => startedAt + index * secondsPerColumn;

  const schedule = () => {
    while (timeOf(nextColumn) < context.currentTime + SCHEDULE_AHEAD_SECONDS) {
      if (!shouldLoop && nextColumn > 0 && nextColumn % columns.length === 0) {
        queue.push({ column: null, time: timeOf(nextColumn) });
        clearInterval(timer);
        timer = null;
        return;
      }

      const startTime = timeOf(nextColumn);
      const column = nextColumn % columns.length;
      const columnSeconds = secondsPerColumn;

      columns[column].forEach((note) => playNote({ ...note, startTime, columnSeconds }));
      queue.push({ column, time: startTime });

      nextColumn += 1;
    }
  };

  const stop = () => {
    clearInterval(timer);
    cancelAnimationFrame(frame);
    timer = null;
    frame = null;
    queue = [];

    if (bus) {
      const finished = bus;
      bus = null;

      finished.gain.setValueAtTime(finished.gain.value, context.currentTime);
      finished.gain.linearRampToValueAtTime(SILENCE, context.currentTime + FADE_SECONDS);
      setTimeout(() => finished.disconnect(), FADE_SECONDS * 2000);
    }
  };

  const reportPosition = () => {
    const elapsed = Math.max(context.currentTime - startedAt, 0);

    onPosition((elapsed % runSeconds) / runSeconds);
  };

  const followAudioClock = () => {
    reportPosition();

    while (queue.length && queue[0].time <= context.currentTime) {
      const { column } = queue.shift();

      if (column === null) {
        stop();
        onEnd();
        return;
      }

      onColumn(column);
    }

    frame = requestAnimationFrame(followAudioClock);
  };

  const start = async ({ columns: nextColumns, columnsPerSecond, loop }) => {
    if (!context) {
      context = new (window.AudioContext || window.webkitAudioContext)();
      buildChain();
    }

    stop();

    await context.resume();

    columns = nextColumns;
    secondsPerColumn = 1 / columnsPerSecond;
    shouldLoop = loop;

    nextColumn = 0;
    startedAt = context.currentTime + LEAD_IN_SECONDS;
    runSeconds = columns.length * secondsPerColumn;
    queue = [];

    bus = context.createGain();
    bus.connect(master);

    timer = setInterval(schedule, LOOKAHEAD_MS);
    schedule();
    frame = requestAnimationFrame(followAudioClock);
  };

  const destroy = () => {
    stop();
    context?.close();
    context = null;
    master = null;
    analyser = null;
  };

  const readSpectrum = () => {
    analyser.getByteFrequencyData(spectrum);

    return spectrum;
  };

  return { start, stop, readSpectrum, destroy };
};
