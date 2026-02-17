<script>
const frameDelays = [2000, 1000, 300, 2000];
const frames = [
  {
    // Frame 1
    searchTags: [{ x: 14, width: 24 }],
    highlightPill: null,
    activeTab: 0,
    blueBarX: 10,
    blueBarWidth: 44,
    tabs: [
      { x: 16, width: 28, visible: true }, // Active tab
      { x: 72, width: 28, visible: true },
      { x: 128, width: 28, visible: false }, // Plus button (hidden)
      { x: 140, width: 20, visible: true },
    ],
    plusIconX: 132, // Plus icon at x=132 for frame 1-3
  },
  {
    // Frame 2 - search tags appear
    searchTags: [
      { x: 14, width: 24 },
      { x: 42, width: 48 },
      { x: 94, width: 32 },
    ],
    highlightPill: null,
    activeTab: 0,
    blueBarX: 10,
    blueBarWidth: 44,
    tabs: [
      { x: 16, width: 28, visible: true }, // Active tab
      { x: 72, width: 28, visible: true },
      { x: 128, width: 28, visible: false }, // Plus button (hidden)
      { x: 140, width: 20, visible: true },
    ],
    plusIconX: 132,
  },
  {
    // Frame 3 - highlight pill appears
    searchTags: [
      { x: 14, width: 24 },
      { x: 42, width: 48 },
      { x: 94, width: 32 },
    ],
    highlightPill: { x: 120, y: 11, width: 52, height: 20 },
    activeTab: 0,
    blueBarX: 10,
    blueBarWidth: 44,
    tabs: [
      { x: 16, width: 28, visible: true }, // Active tab
      { x: 72, width: 28, visible: true },
      { x: 128, width: 28, visible: true }, // Plus button becomes visible
      { x: 140, width: 20, visible: true },
    ],
    plusIconX: 132,
  },
  {
    // Frame 4 - tab switches (tabs shift right)
    searchTags: [
      { x: 14, width: 24 },
      { x: 42, width: 48 },
      { x: 94, width: 32 },
    ],
    highlightPill: null,
    activeTab: 2,
    blueBarX: 120,
    blueBarWidth: 44,
    tabs: [
      { x: 16, width: 28, visible: true },
      { x: 72, width: 28, visible: true },
      { x: 128, width: 28, visible: true }, // Now active tab
      { x: 196, width: 20, visible: true }, // Rightmost tab
    ],
    plusIconX: 188, // Plus icon slides to x=188 for frame 4
  },
];

export default {
  name: 'FiltersAnimation',
  data() {
    return {
      frame: 0,
      animationTimeout: null,
    };
  },
  computed: {
    currentFrame() {
      return frames[this.frame];
    },
    normalizedSearchTags() {
      const allPositions = [
        { x: 14, width: 24 },
        { x: 42, width: 48 },
        { x: 94, width: 32 },
      ];

      return allPositions.map((defaultPos, idx) => {
        const currentTag = this.currentFrame.searchTags[idx];
        return {
          x: currentTag ? currentTag.x : defaultPos.x,
          width: currentTag ? currentTag.width : defaultPos.width,
          visible: idx < this.currentFrame.searchTags.length,
        };
      });
    },
    normalizedTabs() {
      return this.currentFrame.tabs.map((tab) => ({
        x: tab.x,
        width: tab.width,
        visible: tab.visible,
      }));
    },
    plusIconX() {
      return this.currentFrame.plusIconX;
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
        this.frame = (this.frame + 1) % frames.length;
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
        <clipPath id="clip0-second">
          <rect width="240" height="170" fill="white" />
        </clipPath>
      </defs>

      <g clip-path="url(#clip0-second)">
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

        <!-- Animated search tags -->
        <rect
          v-for="(tag, idx) in normalizedSearchTags"
          :key="`tag-${idx}`"
          :x="tag.x"
          y="61"
          :width="tag.width"
          height="8"
          rx="4"
          fill="#89888D"
          :style="{ opacity: tag.visible ? 1 : 0 }"
          class="animated-tag"
        />

        <!-- Filter button -->
        <rect x="232" y="56" width="18" height="18" rx="9" stroke="#BFBFC3" stroke-width="2" />

        <!-- Divider -->
        <path d="M10 41H239V43H10V41Z" fill="#DCDCDE" />

        <!-- Highlight pill behind + button (frame 3) -->
        <g :style="{ opacity: currentFrame.highlightPill ? 0.4 : 0 }" class="animated-highlight">
          <rect x="120" y="11" width="52" height="20" rx="10" fill="#1F75CB" />
        </g>

        <!-- Animated tab buttons -->
        <rect
          v-for="(tab, idx) in normalizedTabs"
          :key="`tab-${idx}`"
          :x="tab.x"
          y="17"
          :width="tab.width"
          height="8"
          rx="4"
          :fill="currentFrame.activeTab === idx ? '#626168' : '#BFBFC3'"
          :style="{ opacity: tab.visible ? 1 : 0 }"
          class="animated-tab"
        />

        <!-- Plus icon - slides with its position -->
        <g :style="{ transform: `translateX(${plusIconX - 132}px)` }" class="animated-plus-icon">
          <path
            d="M132 17C132.491 17 132.889 17.398 132.889 17.8889V20.1111H135.111C135.602 20.1111 136 20.5091 136 21C136 21.4909 135.602 21.8889 135.111 21.8889H132.889V24.1111C132.889 24.602 132.491 25 132 25C131.509 25 131.111 24.602 131.111 24.1111V21.8889H128.889C128.398 21.8889 128 21.4909 128 21C128 20.5091 128.398 20.1111 128.889 20.1111H131.111V17.8889C131.111 17.398 131.509 17 132 17Z"
            fill="#BFBFC3"
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
          class="animated-element"
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
  transition: all 0.6s ease-in-out;
}

.animated-tag {
  transition:
    x 0.6s ease-in-out,
    width 0.6s ease-in-out,
    opacity 0.6s ease-in-out;
}

.animated-tab {
  transition:
    x 0.6s ease-in-out,
    width 0.6s ease-in-out,
    fill 0.6s ease-in-out,
    opacity 0.6s ease-in-out;
}

.animated-plus-icon {
  transition: transform 0.6s ease-in-out;
}

.animated-highlight {
  transition: opacity 0.6s ease-in-out;
  mix-blend-mode: multiply;
}
</style>
