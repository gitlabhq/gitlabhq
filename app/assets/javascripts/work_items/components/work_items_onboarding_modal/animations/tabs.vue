<script>
const frameDelays = [2000, 600, 600, 1000, 2000, 50];
const frames = [
  {
    // Frame 1 - pill invisible at starting position
    highlightPill: { x: 118, y: 11 },
    highlightPillOpacity: 0,
    activeTab: 128,
    blueBarX: 121,
    blueBarWidth: 44,
    blueBarOpacity: 1,
    tab2X: 72,
    tab3X: 128,
  },
  {
    // Frame 2 - pill fades in at right position
    highlightPill: { x: 118, y: 11 },
    highlightPillOpacity: 0.4,
    activeTab: 128,
    blueBarX: 121,
    blueBarWidth: 44,
    blueBarOpacity: 1,
    tab2X: 72,
    tab3X: 128,
  },
  {
    // Frame 3 - pill slides left to second tab
    highlightPill: { x: 62, y: 11 },
    highlightPillOpacity: 0.4,
    activeTab: 72,
    blueBarX: 65,
    blueBarWidth: 44,
    blueBarOpacity: 1,
    tab2X: 128, // tab2 moves right
    tab3X: 72, // tab3 moves left
  },
  {
    // Frame 4 - pill fades out at left position
    highlightPill: { x: 62, y: 11 },
    highlightPillOpacity: 0,
    activeTab: 72,
    blueBarX: 65,
    blueBarWidth: 44,
    blueBarOpacity: 1,
    tab2X: 128,
    tab3X: 72,
  },
  {
    // Frame 5 - extra frame to transition highlight pill
    highlightPill: { x: 118, y: 11 },
    highlightPillOpacity: 0,
    activeTab: 72,
    blueBarX: 65,
    blueBarWidth: 44,
    blueBarOpacity: 1,
    tab2X: 128,
    tab3X: 72,
  },
  {
    // Frame 6 - blue bar fades out, pill repositions invisibly for loop
    highlightPill: { x: 118, y: 11 },
    highlightPillOpacity: 0,
    activeTab: 128,
    blueBarX: 121,
    blueBarWidth: 44,
    blueBarOpacity: 0,
    tab2X: 128,
    tab3X: 72,
  },
];

export default {
  name: 'TabsAnimation',
  data() {
    return {
      disableTransitions: false,
      frame: 0,
      animationTimeout: null,
    };
  },
  computed: {
    currentFrame() {
      return frames[this.frame];
    },
  },
  mounted() {
    this.startAnimation();
  },
  beforeDestroy() {
    if (this.animationTimeout) {
      clearTimeout(this.animationTimeout);
    }
  },
  methods: {
    startAnimation() {
      this.scheduleNextFrame();
    },
    scheduleNextFrame() {
      const currentDelay = frameDelays[this.frame];

      this.animationTimeout = setTimeout(() => {
        const nextFrame = (this.frame + 1) % frames.length;

        // Disable transitions when looping from frame 5 back to frame 0
        if (this.frame === 5 && nextFrame === 0) {
          this.disableTransitions = true;
          this.$nextTick(() => {
            this.frame = nextFrame;
            setTimeout(() => {
              this.disableTransitions = false;
            }, 50);
          });
        } else {
          this.frame = nextFrame;
        }

        this.scheduleNextFrame();
      }, currentDelay);
    },
  },
};
</script>

<template>
  <div class="animation-container">
    <svg
      width="240"
      height="170"
      viewBox="0 0 240 170"
      fill="none"
      xmlns="http://www.w3.org/2000/svg"
    >
      <defs>
        <clipPath id="clip0-third">
          <rect width="240" height="170" fill="white" />
        </clipPath>
      </defs>

      <g clip-path="url(#clip0-third)">
        <!-- Border -->
        <rect x="0.5" y="0.5" width="239" height="169" rx="7.5" stroke="#BFBFC3" />

        <!-- Content rows - static -->
        <rect x="8" y="99" width="176" height="8" rx="4" fill="#DCDCDE" />
        <rect x="8" y="87" width="112" height="8" rx="4" fill="#BFBFC3" />
        <rect x="8" y="131.996" width="144" height="8" rx="4" fill="#DCDCDE" />
        <rect x="8" y="120" width="96" height="8" rx="4" fill="#BFBFC3" />
        <rect x="8" y="165" width="160" height="8" rx="4" fill="#DCDCDE" />
        <rect x="8" y="152.996" width="128" height="8" rx="4" fill="#BFBFC3" />

        <!-- Search bar -->
        <rect x="9" y="56" width="217" height="18" rx="9" stroke="#BFBFC3" stroke-width="2" />

        <!-- Search icon -->
        <path
          fill-rule="evenodd"
          clip-rule="evenodd"
          d="M214.254 61C216.052 61 217.509 62.457 217.509 64.2543C217.509 64.8577 217.343 65.4224 217.057 65.9068L218.762 67.6113C219.079 67.929 219.079 68.444 218.762 68.7617C218.444 69.0794 217.929 69.0794 217.611 68.7617L215.907 67.0573C215.422 67.3435 214.858 67.5085 214.254 67.5085C212.457 67.5085 211 66.0515 211 64.2543C211 62.457 212.457 61 214.254 61ZM214.254 62.6271C213.356 62.6271 212.627 63.3556 212.627 64.2543C212.627 65.1529 213.356 65.8814 214.254 65.8814C215.153 65.8814 215.881 65.1529 215.881 64.2543C215.881 63.3556 215.153 62.6271 214.254 62.6271Z"
          fill="#BFBFC3"
        />

        <!-- Search tags - static -->
        <rect x="14" y="61" width="24" height="8" rx="4" fill="#89888D" />
        <rect x="42" y="61" width="40" height="8" rx="4" fill="#89888D" />

        <!-- Filter button -->
        <rect x="232" y="56" width="18" height="18" rx="9" stroke="#BFBFC3" stroke-width="2" />

        <!-- Divider -->
        <path d="M8 41H239V43H8V41Z" fill="#DCDCDE" />

        <!-- Animated highlight pill -->
        <g
          :style="{
            opacity:
              currentFrame.highlightPillOpacity !== undefined
                ? currentFrame.highlightPillOpacity
                : 0,
          }"
          class="animated-highlight"
        >
          <rect
            :x="currentFrame.highlightPill.x"
            :y="currentFrame.highlightPill.y"
            width="52"
            height="20"
            rx="10"
            fill="#1F75CB"
          />
        </g>

        <!-- Tab buttons - static tabs -->
        <rect x="184" y="17" width="28" height="8" rx="4" fill="#BFBFC3" />
        <rect x="16" y="17" width="28" height="8" rx="4" fill="#BFBFC3" />

        <!-- Tab 3 - moves from x=128 to x=72 -->
        <g
          :style="{ transform: `translateX(${currentFrame.tab3X - 128}px)` }"
          :class="{
            'animated-tab-group': !disableTransitions,
            'no-transition': disableTransitions,
          }"
        >
          <rect
            x="128"
            y="17"
            width="28"
            height="8"
            rx="4"
            :fill="currentFrame.activeTab === currentFrame.tab3X ? '#626168' : '#BFBFC3'"
            :class="{
              'animated-tab-fill': !disableTransitions,
              'no-transition': disableTransitions,
            }"
          />
        </g>

        <!-- Tab 2 - moves from x=72 to x=128 -->
        <g
          :style="{ transform: `translateX(${currentFrame.tab2X - 72}px)` }"
          :class="{
            'animated-tab-group': !disableTransitions,
            'no-transition': disableTransitions,
          }"
        >
          <rect
            x="72"
            y="17"
            width="28"
            height="8"
            rx="4"
            :fill="currentFrame.activeTab === currentFrame.tab2X ? '#626168' : '#BFBFC3'"
            :class="{
              'animated-tab-fill': !disableTransitions,
              'no-transition': disableTransitions,
            }"
          />
        </g>

        <!-- Animated blue underline bar -->
        <rect
          :x="currentFrame.blueBarX"
          y="39"
          :width="currentFrame.blueBarWidth"
          height="4"
          rx="2"
          fill="#1F75CB"
          :style="{
            opacity: currentFrame.blueBarOpacity !== undefined ? currentFrame.blueBarOpacity : 1,
          }"
          :class="{ 'animated-element': !disableTransitions, 'no-transition': disableTransitions }"
        />
      </g>
    </svg>
  </div>
</template>

<style scoped>
.animation-container {
  width: 240px;
  height: 170px;
  position: relative;
  margin: 0 auto;
}

.animation-container svg {
  display: block;
  background: transparent;
  fill: none;
}

.animated-element {
  transition:
    x 0.6s ease-in-out,
    width 0.6s ease-in-out,
    opacity 0.6s ease-in-out;
}

.animated-highlight {
  transition: opacity 0.6s ease-in-out;
  mix-blend-mode: multiply;
}

.animated-highlight rect {
  transition:
    x 0.6s ease-in-out,
    y 0.6s ease-in-out;
}

.animated-tab-group {
  transition: transform 0.6s ease-in-out;
}

.animated-tab-fill {
  transition: fill 0.6s ease-in-out;
}

.no-transition {
  transition: none !important;
}
</style>
