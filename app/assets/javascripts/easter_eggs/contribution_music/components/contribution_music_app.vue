<script>
import {
  GlModal,
  GlButton,
  GlIcon,
  GlLoadingIcon,
  GlAlert,
  GlLink,
  GlSprintf,
  GlAvatar,
  GlTooltipDirective,
  GlResizeObserverDirective,
} from '@gitlab/ui';
import { __, n__, sprintf, formatNumber } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime_utility';
import { getMonthNames } from '~/lib/utils/datetime/date_format_utility';
import {
  ARROW_LEFT_KEY,
  ARROW_RIGHT_KEY,
  ARROW_UP_KEY,
  ARROW_DOWN_KEY,
  HOME_KEY,
  END_KEY,
  PAGE_UP_KEY,
  PAGE_DOWN_KEY,
} from '~/lib/utils/keys';
import AjaxCache from '~/lib/utils/ajax_cache';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import { userPath } from '~/lib/utils/path_helpers/user';
import { newUserSessionPath } from '~/lib/utils/path_helpers/routes';
import ConfirmUnsavedChangesDialog from '~/vue_shared/components/confirm_unsaved_changes_dialog.vue';
import { createPlayer, isAudioSupported } from '../synth';
import { buildWeeks, toColumns, deriveSettings, pickVariant } from '../utils';
import {
  isVideoSupported,
  recordVideo,
  VideoInterruptedError,
  drawLogo,
  drawQrCode,
  drawVideoPreview,
  monthLabels,
} from '../video';
import { createVisualizer, prefersReducedMotion } from '../visualizer';
import { glowCell } from '../shimmer';
import { drawEmptyWave } from '../empty_wave';
import {
  SCALES,
  KEYS,
  I18N,
  BRAND_COLORS,
  BRAND_HOLD_MS,
  BRAND_FADE_MS,
  WAVE_FAINT_OPACITY,
  WAVE_VISIBLE,
  TRANSCEND_URL,
  TRANSCEND_PHASES,
  COLUMNS_PER_BEAT,
  DEFAULT_BPM,
  COPY_FEEDBACK_MS,
  VIDEO_FILENAME,
  MIN_ACTIVE_DAYS,
  VIDEO_THEME,
} from '../constants';

// Below this many pixels per week, the whole year won't fit, so the graph scrolls under a
// fixed playhead like the video does.
const MIN_FULL_WEEK_WIDTH = 16;
// Caps a week's width by the viewport height, so on a wide, short window the graph can't
// grow taller than the space it has.
const MAX_FULL_WEEK_VH = 5;
const MAX_GRAPH_WIDTH = 2400;
const COMPACT_WIDTH = 720;
const SCROLLING_WEEK_WIDTH = 30;
const MIN_MONTH_LABEL_WEEKS = 3;
// Same proportion to the eyebrow text as in the video (40px logo beside 28px text).
const LOGO_HEIGHT = 20;
// Entrance timing: the header settles top to bottom, then the year sweeps in week by week.
const ENTER_DELAYS = { header: 0, byline: 80, message: 160, graph: 250, controls: 400 };
const ENTER_WEEK_STAGGER_MS = 10;
// Below this, "You shipped" oversells a quiet year.
const MIN_SHIPPED_CONTRIBUTIONS = 50;

export default {
  name: 'ContributionMusicApp',
  components: {
    GlModal,
    GlButton,
    GlIcon,
    GlLoadingIcon,
    GlAlert,
    GlLink,
    GlSprintf,
    GlAvatar,
    ConfirmUnsavedChangesDialog,
    // Draws itself on mount, since the modal can replace its content after opening.
    VideoPreview: {
      props: { content: { type: Object, required: true } },
      mounted() {
        drawVideoPreview(this.$el, this.content);
      },
      render(createElement) {
        return createElement('canvas', { attrs: { 'aria-hidden': 'true' } });
      },
    },
    QrCode: {
      props: { url: { type: String, required: true } },
      mounted() {
        drawQrCode(this.$el, this.url);
      },
      render(createElement) {
        return createElement('canvas', { attrs: { 'aria-hidden': 'true' } });
      },
    },
    PlayerLogo: {
      mounted() {
        drawLogo(this.$el, LOGO_HEIGHT);
      },
      render(createElement) {
        return createElement('canvas', { attrs: { role: 'img', 'aria-label': 'GitLab' } });
      },
    },
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    GlResizeObserver: GlResizeObserverDirective,
  },
  props: {
    calendarPath: {
      type: String,
      required: true,
    },
    utcOffset: {
      type: Number,
      required: true,
    },
    firstDayOfWeek: {
      type: Number,
      required: true,
    },
    username: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: false,
      default: null,
    },
    currentUsername: {
      type: String,
      required: false,
      default: null,
    },
    avatarUrl: {
      type: String,
      required: false,
      default: null,
    },
    // Opened right after the song played through on the page's own calendar.
    hasPlayed: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['hidden'],
  i18n: I18N,
  transcendUrl: TRANSCEND_URL,
  enterDelays: ENTER_DELAYS,
  data() {
    return {
      visible: true,
      isLoading: true,
      hasError: false,
      weeks: [],
      isPlaying: false,
      isShown: false,
      hasStarted: false,
      passedWeeks: [],
      isFadingColors: false,
      focusedCell: { weekIndex: 0, dayIndex: 0 },
      focusedCellId: null,
      scale: SCALES[0].value,
      musicKey: 0,
      bpm: DEFAULT_BPM,
      copyState: null,
      isRecording: false,
      videoError: null,
      isDownloadOpen: false,
      graphWidth: 0,
    };
  },
  computed: {
    isAudioSupported() {
      return isAudioSupported();
    },
    intervals() {
      return SCALES.find(({ value }) => value === this.scale).intervals;
    },
    columns() {
      return toColumns({ weeks: this.weeks, intervals: this.intervals, keyOffset: this.musicKey });
    },
    isSilent() {
      const activeDays = this.weeks.flat().filter(({ count }) => count > 0).length;

      return !this.isLoading && activeDays < MIN_ACTIVE_DAYS;
    },
    navigationCells() {
      return this.weeks.flatMap((week, weekIndex) =>
        week.map((cell, dayIndex) => ({ weekIndex, dayIndex, cell })),
      );
    },
    focusableCells() {
      return this.navigationCells.filter(({ cell }) => cell.date !== null);
    },
    horizontalCells() {
      return [...this.focusableCells].sort(
        (a, b) => a.dayIndex - b.dayIndex || a.weekIndex - b.weekIndex,
      );
    },
    columnsPerSecond() {
      return (this.bpm / 60) * COLUMNS_PER_BEAT;
    },
    isOwnProfile() {
      return this.username === this.currentUsername;
    },
    modalTitle() {
      return this.titleFor(this.isOwnProfile);
    },
    canShareVideo() {
      return this.isOwnProfile && isVideoSupported();
    },
    // Below this, the share buttons drop their text and show just their icons.
    isCompact() {
      return this.graphWidth < COMPACT_WIDTH;
    },
    videoContent() {
      return {
        weeks: this.weeks,
        stamp: this.videoStamp,
        title: this.$options.i18n.videoTitle,
        message: sprintf(this.$options.i18n.videoMessage, { user: `@${this.username}` }, false),
        url: this.shareUrl,
        name: this.name,
        username: this.username,
        avatarUrl: this.avatarUrl,
      };
    },
    downloadPrimary() {
      const { generating, generateVideo } = this.$options.i18n;

      return {
        text: this.isRecording ? generating : generateVideo,
        attributes: { variant: 'confirm', loading: this.isRecording },
      };
    },
    downloadCancel() {
      return { text: this.$options.i18n.cancel, attributes: { disabled: this.isRecording } };
    },
    ownSongPath() {
      if (this.isOwnProfile) {
        return null;
      }

      return this.currentUsername
        ? `${userPath({ username: this.currentUsername })}?play`
        : newUserSessionPath({ redirect_to_referer: 'yes', organizationPath: null });
    },
    shareUrl() {
      return `${window.location.origin}${userPath({ username: this.username })}?play`;
    },
    copyLabel() {
      const { copied, copyFailed, copyLink } = this.$options.i18n;

      return { copied, failed: copyFailed }[this.copyState] ?? copyLink;
    },
    ownSongMessage() {
      const { alsoYours, alsoSignIn } = this.$options.i18n;

      return this.currentUsername ? alsoYours : alsoSignIn;
    },
    playerState() {
      if (this.isLoading) {
        return 'loading';
      }

      if (this.hasError) {
        return 'error';
      }

      if (!this.isAudioSupported) {
        return 'unsupported';
      }

      return this.isSilent ? 'empty' : 'ready';
    },
    // Without data yet, show an empty year with the real dates, so the layout doesn't jump.
    isPlaceholder() {
      return ['loading', 'error'].includes(this.playerState);
    },
    // Anything but a playable song: the graph is shown for context but can't be explored.
    isInert() {
      return this.playerState !== 'ready';
    },
    isSilentState() {
      return ['empty', 'unsupported'].includes(this.playerState);
    },
    ownSongLabel() {
      const { playYourSong, signInToPlay } = this.$options.i18n;

      return this.currentUsername ? playYourSong : signInToPlay;
    },
    displayWeeks() {
      return this.isPlaceholder
        ? buildWeeks({
            timestamps: {},
            utcOffset: this.utcOffset,
            firstDayOfWeek: this.firstDayOfWeek,
          })
        : this.weeks;
    },
    stateMessage() {
      const { i18n } = this.$options;

      return {
        loading: null,
        error: null,
        unsupported: { title: i18n.unsupportedTitle, description: i18n.unsupportedDescription },
        empty: {
          title: i18n.emptyTitle,
          description: this.isOwnProfile
            ? i18n.emptyDescription
            : sprintf(i18n.emptyDescriptionOther, { user: `@${this.username}` }, false),
        },
        ready: { title: this.songMessage },
      }[this.playerState];
    },
    // Before the player, a few lines about the year, until the song is played again.
    isIntro() {
      return this.playerState === 'ready' && !this.hasStarted;
    },
    // The count and the song's settings are slots, so they can be styled inside the sentences.
    intro() {
      if (!this.isIntro) {
        return null;
      }

      const { i18n } = this.$options;
      const total = this.weeks.flat().reduce((sum, { count }) => sum + count, 0);

      return {
        total: sprintf(
          n__(
            'ContributionMusic|%{countStart}%{count}%{countEnd} contribution in one year.',
            'ContributionMusic|%{countStart}%{count}%{countEnd} contributions in one year.',
            total,
          ),
          { count: formatNumber(total) },
          false,
        ),
        shipped:
          total >= MIN_SHIPPED_CONTRIBUTIONS
            ? i18n.introShipped[this.isOwnProfile ? 'own' : 'other']
            : null,
        tune: this.isOwnProfile ? i18n.introTune : i18n.introTuneOther,
        settings: {
          key: KEYS[this.musicKey].text,
          scale: SCALES.find(({ value }) => value === this.scale).text,
          bpm: this.bpm,
        },
      };
    },
    transcend() {
      const now = Date.now();
      const phase = TRANSCEND_PHASES.find(({ until }) => now < Date.parse(until));

      if (!this.isIntro || !phase) {
        return null;
      }

      const { transcendStep, transcendStepOther } = this.$options.i18n;

      return {
        step: this.isOwnProfile
          ? transcendStep
          : sprintf(transcendStepOther, { user: `@${this.username}` }, false),
        message: phase.message,
      };
    },
    songMessage() {
      const seed = `${this.username}:${this.weeks.flatMap((week) => week.map(({ count }) => count))}`;
      const { own, other = own } = pickVariant(this.$options.i18n.videoMessages, seed);

      return this.isOwnProfile ? own : sprintf(other, { user: `@${this.username}` }, false);
    },
    videoStamp() {
      return sprintf(
        this.$options.i18n.videoStamp,
        {
          key: KEYS[this.musicKey].text,
          scale: SCALES.find(({ value }) => value === this.scale).text,
          bpm: this.bpm,
        },
        false,
      );
    },
    waveStyle() {
      return this.isSilentState
        ? null
        : { opacity: WAVE_FAINT_OPACITY, transform: `translateY(${(WAVE_VISIBLE - 1) * 100}%)` };
    },
    themeStyle() {
      return {
        '--contribution-music-background': VIDEO_THEME.background,
        '--contribution-music-text': VIDEO_THEME.text,
        '--contribution-music-muted': VIDEO_THEME.muted,
        '--contribution-music-accent': VIDEO_THEME.accent,
      };
    },
    isFullGraph() {
      return this.graphWidth / this.displayWeeks.length >= MIN_FULL_WEEK_WIDTH;
    },
    trackStyle() {
      return this.isFullGraph
        ? {
            maxWidth: `min(${MAX_GRAPH_WIDTH}px,${this.displayWeeks.length * MAX_FULL_WEEK_VH}vh)`,
            marginInline: 'auto',
          }
        : { width: `${this.displayWeeks.length * SCROLLING_WEEK_WIDTH}px` };
    },
    monthMarkers() {
      const names = getMonthNames(true);
      const labels = monthLabels(this.displayWeeks);

      return labels
        .filter(
          ({ weekIndex }, index) =>
            (labels[index + 1]?.weekIndex ?? Infinity) - weekIndex >= MIN_MONTH_LABEL_WEEKS,
        )
        .map(({ weekIndex, month }) => ({
          weekIndex,
          name: names[month],
          left: `${(weekIndex / this.displayWeeks.length) * 100}%`,
        }));
    },
  },
  created() {
    this.lastPosition = 0;
    this.colorsRun = 0;
    this.player = createPlayer({
      onColumn: (column) => this.shimmerWeek(column),
      onPosition: (position) => {
        this.positionGraph(position);
        this.visualizer?.draw(this.player.readSpectrum());
      },
      onEnd: () => {
        this.isPlaying = false;
        this.fadeColors();
      },
    });
  },
  mounted() {
    this.load();
  },
  beforeDestroy() {
    clearTimeout(this.copyStateTimeout);
    clearTimeout(this.colorsTimeout);
    this.player.destroy();
  },
  methods: {
    async load() {
      this.isLoading = true;
      this.hasError = false;

      try {
        const timestamps = await AjaxCache.retrieve(this.calendarPath);
        this.weeks = buildWeeks({
          timestamps,
          utcOffset: this.utcOffset,
          firstDayOfWeek: this.firstDayOfWeek,
        });

        const derived = deriveSettings(this.weeks);

        if (derived) {
          this.musicKey = derived.musicKey;
          this.scale = derived.scale;
          this.bpm = derived.bpm;
        }

        const [first] = this.focusableCells;

        if (first) {
          this.focusedCell = { weekIndex: first.weekIndex, dayIndex: first.dayIndex };
        }
      } catch {
        this.hasError = true;
      } finally {
        this.isLoading = false;
      }

      this.focusIntro();
    },
    onShown() {
      this.isShown = true;
      this.focusIntro();
    },
    // Once both the modal and the data are ready; GlModal focuses the close button first.
    focusIntro() {
      if (this.isShown && this.isIntro) {
        this.$nextTick(() => this.$refs.introPlay?.$el.focus());
      }
    },
    async playFromIntro() {
      this.hasStarted = true;
      await this.$nextTick();
      this.restart();
      this.$refs.playButton?.focus();
    },
    titleFor(isOwn) {
      return isOwn
        ? this.$options.i18n.title
        : sprintf(this.$options.i18n.titleOther, { name: this.name ?? `@${this.username}` }, false);
    },
    contributionText(count) {
      return count > 0 ? n__('%d contribution', '%d contributions', count) : __('No contributions');
    },
    enterDelay(ms) {
      return { '--contribution-music-enter-delay': `${ms}ms` };
    },
    weekEnterDelay(weekIndex) {
      return this.enterDelay(ENTER_DELAYS.graph + weekIndex * ENTER_WEEK_STAGGER_MS);
    },
    cellTooltip(cell) {
      if (!cell.date) {
        return '';
      }

      const dateText = localeDateFormat.asDateFullWithWeekday.format(cell.date);

      return `${this.contributionText(cell.count)}<br /><span class="gl-text-neutral-300">${dateText}</span>`;
    },
    cellAriaLabel(cell) {
      if (!cell.date) {
        return null;
      }

      return sprintf(__('%{contributions} on %{date}'), {
        contributions: this.contributionText(cell.count),
        date: localeDateFormat.asDateFullWithWeekday.format(cell.date),
      });
    },
    cellId(weekIndex, dayIndex) {
      return `contribution-music-cell-${weekIndex}-${dayIndex}`;
    },
    cellTabIndex(weekIndex, dayIndex) {
      const isFocused =
        this.focusedCell.weekIndex === weekIndex && this.focusedCell.dayIndex === dayIndex;

      return isFocused ? '0' : '-1';
    },
    focusCell(weekIndex, dayIndex) {
      this.focusedCell = { weekIndex, dayIndex };

      this.$nextTick(() => {
        this.$refs.grid?.querySelector(`#${this.cellId(weekIndex, dayIndex)}`)?.focus();
      });
    },
    focusCellAt(cells, index) {
      const target = cells[index];

      if (target) {
        this.focusCell(target.weekIndex, target.dayIndex);
      }
    },
    indexOfCell(cells, weekIndex, dayIndex) {
      return cells.findIndex((cell) => cell.weekIndex === weekIndex && cell.dayIndex === dayIndex);
    },
    moveHorizontal(weekIndex, dayIndex, delta) {
      const cells = this.horizontalCells;

      this.focusCellAt(cells, this.indexOfCell(cells, weekIndex, dayIndex) + delta);
    },
    moveVertical(weekIndex, dayIndex, delta) {
      const cells = this.focusableCells;

      this.focusCellAt(cells, this.indexOfCell(cells, weekIndex, dayIndex) + delta);
    },
    focusEndOfWeek(weekIndex, last) {
      const inWeek = this.focusableCells.filter((cell) => cell.weekIndex === weekIndex);

      this.focusCellAt(inWeek, last ? inWeek.length - 1 : 0);
    },
    onCellKeyDown(event, weekIndex, dayIndex) {
      const moves = {
        [ARROW_LEFT_KEY]: () => this.moveHorizontal(weekIndex, dayIndex, -1),
        [ARROW_RIGHT_KEY]: () => this.moveHorizontal(weekIndex, dayIndex, 1),
        [ARROW_UP_KEY]: () => this.moveVertical(weekIndex, dayIndex, -1),
        [ARROW_DOWN_KEY]: () => this.moveVertical(weekIndex, dayIndex, 1),
        [PAGE_UP_KEY]: () => this.moveHorizontal(weekIndex, dayIndex, -4),
        [PAGE_DOWN_KEY]: () => this.moveHorizontal(weekIndex, dayIndex, 4),
        [HOME_KEY]: () => this.focusEndOfWeek(weekIndex, false),
        [END_KEY]: () => this.focusEndOfWeek(weekIndex, true),
      };

      const move = moves[event.key];

      if (move) {
        event.preventDefault();
        move();
      }
    },
    cellStyle(weekIndex, dayIndex, cell) {
      const hasFocus = this.focusedCellId === this.cellId(weekIndex, dayIndex);

      const isPassed = cell.level > 0 && this.passedWeeks.includes(weekIndex);

      return {
        backgroundColor: isPassed ? BRAND_COLORS[cell.level] : VIDEO_THEME.cells[cell.level],
        transition: this.isFadingColors ? `background-color ${BRAND_FADE_MS}ms` : null,
        visibility: cell.date ? null : 'hidden',
        position: hasFocus ? 'relative' : null,
        zIndex: hasFocus ? '1' : null,
      };
    },
    // Animated directly rather than through reactive styles, so each sweep runs its full length
    // even after the playhead has moved on.
    shimmerWeek(weekIndex) {
      const days = this.$refs.grid?.children[weekIndex]?.children ?? [];
      const reducedMotion = prefersReducedMotion();
      const columnMs = 1000 / this.columnsPerSecond;
      const step = this.$refs.track.offsetWidth / this.weeks.length;
      const run = this.colorsRun;

      this.weeks[weekIndex]?.forEach(({ level }, dayIndex) => {
        if (level > 0 && days[dayIndex]) {
          const color = BRAND_COLORS[level];

          glowCell(days[dayIndex], { level, color, columnMs, step, reducedMotion })
            .finished.then(() => this.markPassed(weekIndex, run))
            .catch(() => {});
        }
      });
    },
    // A sweep can finish after the song has restarted, which has reset the colors.
    markPassed(weekIndex, run) {
      if (run === this.colorsRun && !this.passedWeeks.includes(weekIndex)) {
        this.passedWeeks.push(weekIndex);
      }
    },
    resetColors() {
      clearTimeout(this.colorsTimeout);
      this.colorsRun += 1;
      this.isFadingColors = false;
      this.passedWeeks = [];
    },
    // Passed days keep their brand colors for a moment after the song stops, then fade back.
    fadeColors() {
      clearTimeout(this.colorsTimeout);
      this.colorsTimeout = setTimeout(() => {
        this.colorsRun += 1;
        this.isFadingColors = true;
        this.passedWeeks = [];
        this.colorsTimeout = setTimeout(() => {
          this.isFadingColors = false;
        }, BRAND_FADE_MS);
      }, BRAND_HOLD_MS);
    },
    // Only width matters here. Reacting a frame later, and not to height, keeps the layout switch
    // from triggering another notification in the same frame.
    onGraphResize({ contentRect }) {
      const { width } = contentRect;

      if (width === this.graphWidth) {
        return;
      }

      requestAnimationFrame(() => {
        this.graphWidth = width;
        this.$nextTick(() => this.positionGraph(this.lastPosition));
      });
    },
    // The full year stays put under a moving playhead; a narrow one scrolls under a fixed one.
    positionGraph(position) {
      const { track, grid, playhead } = this.$refs;

      if (!track || !playhead) {
        return;
      }

      // The month row scales with the graph, so measure where the cells start.
      playhead.style.top = `${track.offsetTop + grid.offsetTop}px`;

      this.lastPosition = position;
      track.style.transform = this.isFullGraph
        ? ''
        : `translateX(${this.graphWidth / 2 - position * track.offsetWidth}px)`;
      playhead.style.left = this.isFullGraph
        ? `${track.offsetLeft + position * track.offsetWidth}px`
        : '50%';
    },
    redrawEmptyWave() {
      if (this.$refs.emptyWave) {
        drawEmptyWave(this.$refs.emptyWave);
      }
    },
    resizeVisualizer() {
      this.visualizer?.resize();
    },
    onCellFocus(weekIndex, dayIndex) {
      this.focusedCellId = this.cellId(weekIndex, dayIndex);

      if (!this.isFullGraph && !this.isPlaying) {
        this.positionGraph((weekIndex + 0.5) / this.weeks.length);
      }
    },
    async restart() {
      if (!this.visualizer && this.$refs.visualizer && !prefersReducedMotion()) {
        this.visualizer = createVisualizer(this.$refs.visualizer);
      }

      this.resetColors();
      await this.player.start({
        columns: this.columns,
        columnsPerSecond: this.columnsPerSecond,
        loop: true,
      });
      this.isPlaying = true;
    },
    toggle() {
      if (this.isPlaying) {
        this.player.stop();
        this.isPlaying = false;
        this.fadeColors();

        return;
      }

      this.restart();
    },
    async onCopy(event) {
      clearTimeout(this.copyStateTimeout);

      try {
        await copyToClipboard(this.shareUrl, event.currentTarget);
        this.copyState = 'copied';
      } catch {
        this.copyState = 'failed';
      }

      this.copyStateTimeout = setTimeout(() => {
        this.copyState = null;
      }, COPY_FEEDBACK_MS);
    },
    openDownload() {
      if (this.isPlaying) {
        this.toggle();
      }

      this.isDownloadOpen = true;
    },
    onDownloadPrimary(event) {
      event.preventDefault();
      this.generateVideo();
    },
    // Generation can't survive the tab being left, so both dialogs stay until it's done.
    preventHideWhileRecording(event) {
      if (this.isRecording) {
        event.preventDefault();
      }
    },
    onDownloadHidden() {
      this.isDownloadOpen = false;
      this.videoError = null;
    },
    async generateVideo() {
      this.isRecording = true;
      this.videoError = null;

      try {
        const { blob, extension } = await recordVideo({
          ...this.videoContent,
          columns: this.columns,
          columnsPerSecond: this.columnsPerSecond,
        });

        const href = URL.createObjectURL(blob);
        const link = document.createElement('a');
        link.href = href;
        link.download = `${this.username}-${VIDEO_FILENAME}.${extension}`;
        link.click();
        setTimeout(() => URL.revokeObjectURL(href));
        this.isDownloadOpen = false;
      } catch (error) {
        const { videoInterrupted, videoError } = this.$options.i18n;

        this.videoError = error instanceof VideoInterruptedError ? videoInterrupted : videoError;
      } finally {
        this.isRecording = false;
      }
    },
    onHidden() {
      this.player.stop();
      this.$emit('hidden');
    },
  },
};
</script>

<template>
  <gl-modal
    modal-id="contribution-music"
    :visible="visible"
    :aria-label="modalTitle"
    modal-class="contribution-music-modal"
    content-class="contribution-music-modal-content"
    body-class="!gl-p-0"
    hide-header
    hide-footer
    @hide="preventHideWhileRecording"
    @shown="onShown"
    @hidden="onHidden"
  >
    <confirm-unsaved-changes-dialog :has-unsaved-changes="isRecording" />
    <div
      class="contribution-music-player gl-dark-scope gl-relative gl-flex gl-h-full gl-flex-col gl-overflow-hidden gl-p-6"
      :style="themeStyle"
    >
      <!-- Full strength only when there's no song, where it stands in for the missing one. -->
      <canvas
        ref="emptyWave"
        v-gl-resize-observer="redrawEmptyWave"
        class="gl-pointer-events-none gl-absolute gl-inset-0 gl-h-full gl-w-full"
        :style="waveStyle"
        aria-hidden="true"
      ></canvas>
      <header
        class="contribution-music-enter gl-relative gl-flex gl-items-center gl-justify-between gl-gap-5"
        :style="enterDelay($options.enterDelays.header)"
      >
        <!-- Inline, not flex: only inline layout honors the logo's shifted baseline. -->
        <div class="contribution-music-muted gl-font-monospace">
          <player-logo />
          <span class="gl-ml-4" aria-hidden="true">/</span>
          <span class="gl-ml-3">{{ $options.i18n.videoTitle }}</span>
        </div>
        <gl-button
          icon="close"
          category="tertiary"
          :aria-label="$options.i18n.close"
          :disabled="isRecording"
          @click="visible = false"
        />
      </header>

      <div
        class="contribution-music-enter gl-relative gl-mt-7 gl-flex gl-items-center gl-gap-5"
        :style="enterDelay($options.enterDelays.byline)"
      >
        <gl-avatar :src="avatarUrl" :size="64" :entity-name="username" aria-hidden="true" />
        <div class="gl-min-w-0">
          <h2 class="gl-heading-1 !gl-mb-1 gl-truncate">{{ name || `@${username}` }}</h2>
          <p v-if="name" class="contribution-music-muted gl-mb-0 gl-font-monospace">
            @{{ username }}
          </p>
        </div>
      </div>

      <div
        aria-live="polite"
        class="contribution-music-enter gl-relative gl-mt-6"
        :style="enterDelay($options.enterDelays.message)"
      >
        <gl-alert
          v-if="playerState === 'error'"
          variant="danger"
          :dismissible="false"
          :primary-button-text="$options.i18n.retry"
          @primary-action="load"
        >
          {{ $options.i18n.error }}
        </gl-alert>
        <p v-else-if="playerState === 'ready' && !isIntro" class="gl-mb-0 gl-text-size-h2">
          {{ stateMessage.title }}
        </p>
      </div>
      <!-- Measured like the graph, so the share buttons know how much room there is. -->
      <div
        v-if="isIntro"
        v-gl-resize-observer="onGraphResize"
        class="contribution-music-enter contribution-music-intro gl-relative gl-my-auto"
        :style="enterDelay($options.enterDelays.message)"
      >
        <p class="contribution-music-intro-lead gl-mb-0">
          <gl-sprintf :message="intro.total">
            <template #count="{ content }">
              <!-- Separators in the regular font, since a monospace comma takes a full digit's width. -->
              <span class="contribution-music-intro-count gl-font-monospace"
                ><span
                  v-for="(part, index) in content.split(/(\D+)/)"
                  :key="index"
                  :class="{ 'gl-font-regular': index % 2 }"
                  >{{ part }}</span
                ></span
              >
            </template>
          </gl-sprintf>
        </p>
        <p
          v-if="intro.shipped"
          class="contribution-music-enter contribution-music-intro-body gl-mb-0 gl-mt-5"
          :style="enterDelay($options.enterDelays.graph)"
        >
          {{ intro.shipped }}
        </p>
        <p
          class="contribution-music-enter contribution-music-intro-body gl-mb-0 gl-mt-7"
          :style="enterDelay($options.enterDelays.graph)"
        >
          <gl-sprintf :message="intro.tune">
            <template #key>
              <span class="contribution-music-intro-setting gl-font-monospace">{{
                intro.settings.key
              }}</span>
            </template>
            <template #scale>
              <span class="contribution-music-intro-setting gl-font-monospace">{{
                intro.settings.scale
              }}</span>
            </template>
            <template #bpm>
              <span class="contribution-music-intro-setting gl-font-monospace">{{
                intro.settings.bpm
              }}</span>
            </template>
          </gl-sprintf>
        </p>
        <p
          v-if="transcend"
          class="contribution-music-enter contribution-music-intro-body gl-mb-0 gl-mt-7"
          :style="enterDelay($options.enterDelays.graph)"
        >
          {{ transcend.step }}
          <gl-sprintf :message="transcend.message">
            <template #link="{ content }">
              <gl-link :href="$options.transcendUrl" target="_blank">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>
        <gl-button
          ref="introPlay"
          variant="confirm"
          class="contribution-music-enter gl-mt-7"
          :style="enterDelay($options.enterDelays.controls)"
          @click="playFromIntro"
        >
          {{ hasPlayed ? $options.i18n.playAgain : $options.i18n.play }}
        </gl-button>
      </div>
      <template v-if="displayWeeks.length">
        <p
          v-if="ownSongPath && playerState === 'ready'"
          class="contribution-music-enter contribution-music-muted gl-relative gl-mb-0 gl-mt-3"
          :style="enterDelay($options.enterDelays.message)"
        >
          <gl-sprintf :message="ownSongMessage">
            <template #link="{ content }">
              <gl-link :href="ownSongPath">{{ content }}</gl-link>
            </template>
          </gl-sprintf>
        </p>

        <div v-if="!isIntro" class="gl-my-auto">
          <div class="gl-relative gl-pb-5 gl-pt-6">
            <div
              v-gl-resize-observer="onGraphResize"
              class="gl-relative gl-overflow-hidden"
              :class="{
                'contribution-music-graph-scrolling': !isFullGraph,
                'contribution-music-graph-muted': isSilentState,
              }"
              :role="isInert ? null : 'group'"
              :aria-label="isInert ? null : $options.i18n.graphLabel"
              :aria-hidden="isInert ? 'true' : null"
            >
              <div ref="track" class="contribution-music-track gl-relative" :style="trackStyle">
                <div
                  class="contribution-music-enter contribution-music-months contribution-music-muted gl-relative gl-font-monospace"
                  :style="enterDelay($options.enterDelays.graph)"
                  aria-hidden="true"
                >
                  <span
                    v-for="marker in monthMarkers"
                    :key="marker.weekIndex"
                    class="gl-absolute gl-top-0"
                    :style="{ left: marker.left }"
                  >
                    {{ marker.name }}
                  </span>
                </div>
                <div ref="grid" class="contribution-music-cells gl-flex">
                  <div
                    v-for="(week, weekIndex) in displayWeeks"
                    :key="weekIndex"
                    class="contribution-music-enter contribution-music-cells gl-flex gl-flex-1 gl-flex-col"
                    :style="weekEnterDelay(weekIndex)"
                  >
                    <component
                      :is="cell.date && !isInert ? 'button' : 'div'"
                      v-for="(cell, dayIndex) in week"
                      :id="cellId(weekIndex, dayIndex)"
                      :key="dayIndex"
                      v-gl-tooltip.html="isInert ? '' : cellTooltip(cell)"
                      :type="cell.date && !isInert ? 'button' : null"
                      class="contribution-music-cell gl-aspect-square gl-border-0 gl-p-0"
                      :style="cellStyle(weekIndex, dayIndex, cell)"
                      :aria-label="cellAriaLabel(cell)"
                      :aria-hidden="cell.date ? null : 'true'"
                      :tabindex="isInert ? null : cellTabIndex(weekIndex, dayIndex)"
                      @keydown="onCellKeyDown($event, weekIndex, dayIndex)"
                      @focus="onCellFocus(weekIndex, dayIndex)"
                      @blur="focusedCellId = null"
                    />
                  </div>
                </div>
              </div>
              <div
                v-show="isPlaying || !isFullGraph"
                ref="playhead"
                class="contribution-music-playhead gl-pointer-events-none gl-absolute -gl-bottom-1 gl-w-px"
              ></div>
            </div>
            <!-- Over the dimmed year, so it's clear there's nothing to play. -->
            <div
              v-if="isSilentState"
              aria-live="polite"
              class="gl-absolute gl-inset-0 gl-flex gl-flex-col gl-items-center gl-justify-center gl-px-6 gl-text-center"
            >
              <gl-emoji data-name="mute" class="gl-mb-4 gl-text-size-h1-xl" aria-hidden="true" />
              <p class="gl-mb-0 gl-text-size-h1">{{ stateMessage.title }}</p>
              <p class="contribution-music-empty-description gl-mb-0 gl-mt-3 gl-text-size-h2">
                {{ stateMessage.description }}
              </p>
            </div>
            <div
              v-if="playerState === 'ready'"
              ref="stamp"
              class="contribution-music-enter gl-mt-4"
              :style="[isFullGraph ? trackStyle : null, weekEnterDelay(displayWeeks.length)]"
            >
              <p class="contribution-music-stamp gl-mb-0 gl-font-monospace gl-text-sm">
                {{ videoStamp }}
              </p>
            </div>
          </div>

          <div
            id="contribution-music-controls"
            v-gl-resize-observer="resizeVisualizer"
            class="contribution-music-enter gl-relative gl-flex gl-items-center gl-justify-center"
            :style="[isFullGraph ? trackStyle : null, enterDelay($options.enterDelays.controls)]"
          >
            <gl-button v-if="isSilentState && ownSongPath" variant="confirm" :href="ownSongPath">
              {{ ownSongLabel }}
            </gl-button>
            <div v-else-if="playerState === 'loading'" class="gl-flex gl-h-11 gl-items-center">
              <gl-loading-icon variant="dots" size="lg" :label="$options.i18n.loading" />
            </div>
            <template v-else-if="playerState === 'ready'">
              <canvas
                ref="visualizer"
                :class="{ 'gl-invisible': !isPlaying }"
                class="contribution-music-visualizer gl-pointer-events-none gl-absolute gl-inset-x-0 gl-top-1/2 gl-h-11 gl-w-full -gl-translate-y-1/2"
                aria-hidden="true"
              ></canvas>
              <button
                ref="playButton"
                type="button"
                class="contribution-music-play gl-relative gl-flex gl-h-11 gl-w-11 gl-items-center gl-justify-center gl-rounded-full gl-border-0 focus:gl-focus"
                :aria-label="isPlaying ? $options.i18n.pause : $options.i18n.play"
                :disabled="isRecording"
                @click="toggle"
              >
                <gl-icon :name="isPlaying ? 'pause' : 'play'" :size="32" />
              </button>
            </template>
          </div>
        </div>

        <div
          v-if="playerState === 'ready'"
          class="contribution-music-enter gl-flex gl-flex-col gl-items-end gl-gap-5"
          :style="enterDelay($options.enterDelays.controls)"
        >
          <!-- For moving to a phone, where people are signed in to their social accounts. -->
          <qr-code
            v-if="isOwnProfile && !isCompact"
            :url="shareUrl"
            class="contribution-music-qr"
          />
          <div class="gl-flex gl-gap-3">
            <!-- Keyed: GlButton only checks for text when it renders, not when the slot changes. -->
            <gl-button
              :key="`copy-${isCompact}`"
              v-gl-tooltip="isCompact ? copyLabel : ''"
              :icon="copyState === 'copied' ? 'check' : 'copy-to-clipboard'"
              :aria-label="isCompact ? copyLabel : null"
              aria-live="polite"
              @click="onCopy"
            >
              <template v-if="!isCompact">{{ copyLabel }}</template>
            </gl-button>
            <gl-button
              v-if="canShareVideo"
              :key="`download-${isCompact}`"
              v-gl-tooltip="isCompact ? $options.i18n.downloadVideo : ''"
              icon="download"
              :aria-label="isCompact ? $options.i18n.downloadVideo : null"
              @click="openDownload"
            >
              <template v-if="!isCompact">{{ $options.i18n.downloadVideo }}</template>
            </gl-button>
          </div>
        </div>
      </template>
      <gl-modal
        v-if="canShareVideo"
        modal-id="contribution-music-download"
        :visible="isDownloadOpen"
        :title="$options.i18n.downloadVideo"
        modal-class="gl-dark-scope"
        size="sm"
        :action-primary="downloadPrimary"
        :action-cancel="downloadCancel"
        no-close-on-backdrop
        @primary="onDownloadPrimary"
        @hide="preventHideWhileRecording"
        @hidden="onDownloadHidden"
      >
        <video-preview :content="videoContent" class="contribution-music-download-preview" />
        <p
          class="gl-mb-0 gl-mt-4 gl-text-center"
          :class="videoError ? 'gl-text-danger' : 'gl-text-subtle'"
        >
          {{ videoError || $options.i18n.generatingHint }}
        </p>
      </gl-modal>
    </div>
  </gl-modal>
</template>

<style scoped>
@keyframes contribution-music-enter {
  from {
    opacity: 0;
    transform: translateY(0.5rem);
  }
}

.contribution-music-enter {
  animation: contribution-music-enter 450ms ease-out both;
  animation-delay: var(--contribution-music-enter-delay, 0ms);
}

@media (prefers-reduced-motion: reduce) {
  .contribution-music-enter {
    animation: none;
  }
}

.contribution-music-player {
  background-color: var(--contribution-music-background);
  color: var(--contribution-music-text);
}

.contribution-music-muted {
  color: var(--contribution-music-muted);
}

.contribution-music-stamp {
  color: var(--contribution-music-accent);
  opacity: 0.7;
}

/* Gaps and corners scale with the cells, so the grid keeps its shape at any size. */
.contribution-music-track {
  container-type: inline-size;
}

.contribution-music-cells {
  gap: 0.2cqw;
}

.contribution-music-cell {
  border-radius: 12%;
}

/* 12px at the 1152px-wide graph of a 1200px viewport, scaling with the graph from there. */
.contribution-music-months {
  height: 1.4em;
  /* Unitless, so the line box grows with the font instead of clipping large labels. */
  line-height: 1.4;
  margin-bottom: 0.6em;
  font-size: max(10px, 1.04cqw);
}

.contribution-music-playhead {
  background-color: var(--contribution-music-accent);
}

/* Keeps the lines to a readable length on wide screens. Sizes scale with the viewport, from a
   phone's to a desktop's, so the lead stays the loudest thing on screen at any size. */
.contribution-music-intro {
  max-width: 60rem;
}

.contribution-music-intro-lead {
  font-size: clamp(1.75rem, 1rem + 2.4vw, 3.5rem);
  font-weight: 700;
  line-height: 1.12;
  letter-spacing: -0.02em;
  text-wrap: balance;
}

/* The brand colors the days take on as they play. Large text, where 3:1 is enough, and the
   darkest stop is above it. */
.contribution-music-intro-count {
  background-image: linear-gradient(90deg, #fdf0d5, #fb8017 35%, #f15168 70%, #7862c8);
  background-clip: text;
  color: transparent;
}

.contribution-music-intro-body {
  max-width: 44rem;
  color: #c1bfbe;
  font-size: clamp(1.125rem, 0.95rem + 0.6vw, 1.5rem);
  line-height: 1.45;
  text-wrap: pretty;
}

.contribution-music-intro-setting {
  color: var(--contribution-music-accent);
}

/* Neutral 400, the darkest that keeps AA contrast over the empty wave's brightest pixels. */
.contribution-music-empty-description {
  color: #c1bfbe;
}

/* Faint, so the year stays in the background behind the message. */
.contribution-music-graph-muted {
  opacity: 0.05;
}

.contribution-music-graph-scrolling {
  mask-image: linear-gradient(to right, transparent, black 20%, black 80%, transparent);
}

.contribution-music-visualizer {
  color: var(--gl-button-confirm-primary-background-color-default);
}

.contribution-music-play {
  background-color: var(--gl-button-confirm-primary-background-color-default);
  color: var(--gl-button-confirm-primary-foreground-color-default);
}

.contribution-music-play:hover:not(:disabled) {
  background-color: var(--gl-button-confirm-primary-background-color-hover);
  color: var(--gl-button-confirm-primary-foreground-color-hover);
}

.contribution-music-play:focus-visible {
  background-color: var(--gl-button-confirm-primary-background-color-focus);
  color: var(--gl-button-confirm-primary-foreground-color-focus);
}

.contribution-music-play:active:not(:disabled) {
  background-color: var(--gl-button-confirm-primary-background-color-active);
  color: var(--gl-button-confirm-primary-foreground-color-active);
}
</style>

<style>
.contribution-music-qr {
  display: block;
  width: 7rem;
}

.contribution-music-download-preview {
  display: block;
  width: 12rem;
  margin-inline: auto;
  border-radius: 0.5rem;
}

/* The dialog and content are rendered by GlModal, outside this component's scoped styles. */
.contribution-music-modal .modal-dialog {
  max-width: none;
  margin: 0;
}

.contribution-music-modal .contribution-music-modal-content {
  height: 100vh;
  height: 100dvh;
  border: 0;
  border-radius: 0;
  overflow: hidden;
}
</style>
