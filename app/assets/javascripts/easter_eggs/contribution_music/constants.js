import { __, s__ } from '~/locale';

export const DAYS_IN_THE_WEEK = 7;

export const SCALES = [
  {
    value: 'majorPentatonic',
    anhemitonic: true,
    brightness: 1,
    intervals: [0, 2, 4, 7, 9],
    text: s__('ContributionMusic|Major pentatonic'),
  },
  {
    value: 'minorPentatonic',
    anhemitonic: true,
    brightness: 0.55,
    intervals: [0, 3, 5, 7, 10],
    text: s__('ContributionMusic|Minor pentatonic'),
  },
  {
    value: 'egyptian',
    anhemitonic: true,
    brightness: 0.7,
    intervals: [0, 2, 5, 7, 10],
    text: s__('ContributionMusic|Egyptian'),
  },
  {
    value: 'yo',
    anhemitonic: true,
    brightness: 0.85,
    intervals: [0, 2, 5, 7, 9],
    text: s__('ContributionMusic|Yo (Japanese)'),
  },
  {
    value: 'kumoi',
    brightness: 0.45,
    intervals: [0, 2, 3, 7, 9],
    text: s__('ContributionMusic|Kumoi (Japanese)'),
  },
  {
    value: 'hirajoshi',
    brightness: 0.3,
    intervals: [0, 2, 3, 7, 8],
    text: s__('ContributionMusic|Hirajoshi (Japanese)'),
  },
  {
    value: 'insen',
    brightness: 0.2,
    intervals: [0, 1, 5, 7, 10],
    text: s__('ContributionMusic|In sen (Japanese)'),
  },
  {
    value: 'iwato',
    brightness: 0.1,
    intervals: [0, 1, 5, 6, 10],
    text: s__('ContributionMusic|Iwato (Japanese)'),
  },
  {
    value: 'pelog',
    brightness: 0,
    intervals: [0, 1, 3, 7, 8],
    text: s__('ContributionMusic|Pelog (Balinese)'),
  },

  {
    value: 'ionian',
    brightness: 0.85,
    intervals: [0, 2, 4, 5, 7, 9, 11],
    text: s__('ContributionMusic|Ionian (major)'),
  },
  {
    value: 'dorian',
    brightness: 0.5,
    intervals: [0, 2, 3, 5, 7, 9, 10],
    text: s__('ContributionMusic|Dorian'),
  },
  {
    value: 'phrygian',
    brightness: 0.15,
    intervals: [0, 1, 3, 5, 7, 8, 10],
    text: s__('ContributionMusic|Phrygian'),
  },
  {
    value: 'lydian',
    brightness: 1,
    intervals: [0, 2, 4, 6, 7, 9, 11],
    text: s__('ContributionMusic|Lydian'),
  },
  {
    value: 'mixolydian',
    brightness: 0.65,
    intervals: [0, 2, 4, 5, 7, 9, 10],
    text: s__('ContributionMusic|Mixolydian'),
  },
  {
    value: 'aeolian',
    brightness: 0.35,
    intervals: [0, 2, 3, 5, 7, 8, 10],
    text: s__('ContributionMusic|Aeolian (minor)'),
  },
  {
    value: 'locrian',
    brightness: 0,
    intervals: [0, 1, 3, 5, 6, 8, 10],
    text: s__('ContributionMusic|Locrian'),
  },

  {
    value: 'wholeTone',
    brightness: 1,
    intervals: [0, 2, 4, 6, 8, 10],
    text: s__('ContributionMusic|Whole tone'),
  },
  {
    value: 'phrygianDominant',
    brightness: 0.3,
    intervals: [0, 1, 4, 5, 7, 8, 10],
    text: s__('ContributionMusic|Phrygian dominant'),
  },
  {
    value: 'hungarianMinor',
    brightness: 0,
    intervals: [0, 2, 3, 6, 7, 8, 11],
    text: s__('ContributionMusic|Hungarian minor'),
  },
  {
    value: 'doubleHarmonic',
    brightness: 0.6,
    intervals: [0, 1, 4, 5, 7, 8, 11],
    text: s__('ContributionMusic|Double harmonic'),
  },
];

export const ROOT_MIDI = 48;

export const SEMITONES_IN_OCTAVE = 12;

export const ROW_STEP = 2;

export const WEEK_SHIFT_DEGREES = 4;

// eslint-disable-next-line @gitlab/require-i18n-strings
export const KEYS = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'].map(
  (text, value) => ({ value, text }),
);

export const VOICES = [
  null,
  {
    wave: 'triangle',
    partial: { wave: 'sine', ratio: 2, gain: 0.3, bright: true },
    cutoff: 1800,
    gain: 0.45,
    attack: 0.004,
    decay: 0.5,
  },
  {
    wave: 'sine',
    partial: { wave: 'sine', ratio: 4, gain: 0.35, bright: true },
    cutoff: 3200,
    gain: 0.6,
    attack: 0.005,
    decay: 0.7,
  },
  {
    wave: 'sine',
    partial: { wave: 'sine', ratio: 3.984, gain: 0.22, bright: true },
    cutoff: 5000,
    gain: 0.5,
    attack: 0.006,
    decay: 1.9,
  },
  {
    wave: 'triangle',
    sustain: true,
    partial: { wave: 'triangle', ratio: 1, detune: 14, gain: 1 },
    cutoff: 2600,
    gain: 0.22,
    attack: 0.12,
    decay: 1.4,
  },
];

export const BRIGHT_DECAY = 0.4;

export const GATE = 0.85;
export const RELEASE = 1 - GATE;

export const COLUMNS_PER_BEAT = 2;

export const DEFAULT_BPM = 120;

export const BRIGHTEST_AT_LEVEL = 3;

export const SPARSEST_DENSITY = 0.05;
export const DENSEST_DENSITY = 0.6;
export const DERIVED_MIN_BPM = 95;
export const DERIVED_MAX_BPM = 204;

export const MONTHS_IN_THE_YEAR = 12;

export const MIN_ACTIVE_DAYS = 4;

export const COPY_FEEDBACK_MS = 2000;

export const VIDEO_WIDTH = 1080;
export const VIDEO_HEIGHT = 1920;
export const VIDEO_FPS = 30;
export const VIDEO_FILENAME = 'contribution-song';
export const VIDEO_TAIL_SECONDS = 4;
export const VIDEO_MIME_TYPES = [
  'video/mp4;codecs=avc1,mp4a.40.2',
  'video/mp4',
  'video/webm;codecs=vp9,opus',
  'video/webm',
];
// From the Playlab palette: https://je-demos-b9df07.gitlab.io/builder/01-palette.html
export const VIDEO_THEME = {
  background: '#18171d',
  text: '#f7f7f5',
  muted: '#8a8888',
  accent: '#fb8017',
  cells: ['#28272d', '#483698', '#6a54c0', '#927cd7', '#c9beef'],
  tanuki: ['#e24329', '#fc6d26', '#fca326'],
};

// From the Playlab palette: https://je-demos-b9df07.gitlab.io/builder/01-palette.html
// Days the playhead has passed take these on, one per contribution level, lightest to darkest.
// The lightest is lost against light mode's empty cells, so there level 1 takes the next yellow.
export const BRAND_COLORS = [null, '#fdf0d5', '#fb8017', '#f15168', '#7862c8'];
export const LIGHT_BRAND_COLORS = [null, '#f7b951', '#fb8017', '#f15168', '#7862c8'];
// How long they stay once the song stops, and how long they take to fade back.
export const BRAND_HOLD_MS = 2000;
export const BRAND_FADE_MS = 1500;

// Behind a playable song, the empty state's wave is faint and pushed up past the top edge, so
// only this much of it, from the bottom, shows along the top of the modal and the video.
export const WAVE_FAINT_OPACITY = 0.4;
export const WAVE_VISIBLE = 0.6;

export const I18N = {
  title: s__('ContributionMusic|Your contribution song'),
  titleOther: s__("ContributionMusic|%{name}'s contribution song"),
  alsoYours: s__('ContributionMusic|You can also %{linkStart}check out your own song%{linkEnd}.'),
  alsoSignIn: s__(
    'ContributionMusic|You can also %{linkStart}sign in to check out your own song%{linkEnd}.',
  ),
  copyLink: __('Copy link'),
  copied: s__('ContributionMusic|Link copied'),
  copyFailed: __('Copy failed. Please manually copy the value.'),
  downloadVideo: s__('ContributionMusic|Download video'),
  generating: s__('ContributionMusic|Generating'),
  generateVideo: s__('ContributionMusic|Generate video'),
  cancel: __('Cancel'),
  videoError: s__('ContributionMusic|Could not generate the video.'),
  videoInterrupted: s__(
    'ContributionMusic|Video generation stopped because you left this tab. Keep the tab open until the video downloads.',
  ),
  generatingHint: s__(
    'ContributionMusic|The video generates in real time. Keep this tab open until it downloads.',
  ),
  play: __('Play'),
  pause: __('Pause'),
  close: __('Close'),
  videoTitle: s__('ContributionMusic|The sound of GitLab'),
  introShipped: {
    own: s__("ContributionMusic|You didn't just show up. You shipped."),
    other: s__("ContributionMusic|They didn't just show up. They shipped."),
  },
  introTune: s__(
    'ContributionMusic|We turned it into a song. Key of %{key}. %{scale} scale. %{bpm}\u00a0BPM. Yours alone.',
  ),
  introTuneOther: s__(
    'ContributionMusic|We turned it into a song. Key of %{key}. %{scale} scale. %{bpm}\u00a0BPM. Theirs alone.',
  ),
  videoMessage: s__('ContributionMusic|%{user} and GitLab make beautiful music together.'),
  // Chosen per user and contribution data, so the same song always gets the same line.
  videoMessages: [
    { own: s__('ContributionMusic|We make beautiful music together.') },
    { own: s__('ContributionMusic|The sound of shipping.') },
    { own: s__('ContributionMusic|A year of shipping.') },
    {
      own: s__('ContributionMusic|Your year, merged.'),
      other: s__("ContributionMusic|%{user}'s year, merged."),
    },
    {
      own: s__('ContributionMusic|Your contributions, remixed.'),
      other: s__("ContributionMusic|%{user}'s contributions, remixed."),
    },
  ],
  videoStamp: s__('ContributionMusic|/ %{key} %{scale} · %{bpm} BPM'),
  graphLabel: s__('ContributionMusic|Contribution activity for the last 12 months'),
  emptyTitle: s__('ContributionMusic|Hear that? Neither do I.'),
  emptyDescription: s__(
    "ContributionMusic|There aren't enough contributions in the last year to play.",
  ),
  emptyDescriptionOther: s__(
    "ContributionMusic|%{user} doesn't have enough contributions in the last year to play.",
  ),
  error: s__('ContributionMusic|Could not load contribution activity.'),
  retry: __('Retry'),
  playInPlace: s__('ContributionMusic|Play contribution song'),
  stopInPlace: s__('ContributionMusic|Stop contribution song'),
  openPlayer: s__('ContributionMusic|Open contribution song player'),
  playAgain: s__('ContributionMusic|Play it again'),
  transcendStep: s__('ContributionMusic|Every note in this song is a step you took in GitLab.'),
  transcendStepOther: s__(
    'ContributionMusic|Every note in this song is a step %{user} took in GitLab.',
  ),
  transcendBefore: s__(
    'ContributionMusic|At Transcend on October 6, see how teams ship at agent speed and prove every step. %{linkStart}Register for the livestream%{linkEnd}',
  ),
  transcendDuring: s__(
    'ContributionMusic|Transcend is here. %{linkStart}Watch the livestream%{linkEnd}',
  ),
  transcendAfter: s__('ContributionMusic|%{linkStart}Watch Transcend on demand%{linkEnd}'),
  playYourSong: s__('ContributionMusic|Play your own song'),
  signInToPlay: s__('ContributionMusic|Sign in to play your own song'),
  loading: __('Loading'),
  unsupportedTitle: s__("ContributionMusic|This browser can't play audio."),
  unsupportedDescription: s__(
    'ContributionMusic|Audio might be turned off in your browser settings or by an extension.',
  ),
};

export const TRANSCEND_URL = 'https://about.gitlab.com/events/transcend/virtual/';
// Switches when about.gitlab.com's banner and event page do, in UTC: the event starts at
// 8:00 AM ET on October 6 and goes on demand at 3:00 AM ET on October 7. After the last date the
// line goes away, so a late teardown doesn't keep promoting an old event.
export const TRANSCEND_PHASES = [
  { until: '2026-10-06T12:00:00Z', message: I18N.transcendBefore },
  { until: '2026-10-07T07:00:00Z', message: I18N.transcendDuring },
  { until: '2026-11-01T04:00:00Z', message: I18N.transcendAfter },
];
