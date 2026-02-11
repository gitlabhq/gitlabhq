<script>
const frameDelays = [2000, 1000, 2000];
const frames = [
  {
    highlightX: 9,
    highlightWidth: 18,
    searchTags: [{ x: 12, width: 16 }],
    filterChips: [
      {
        y: 50,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: false },
          { x: 206, w: 4, visible: false },
          { x: 212, w: 4, visible: false },
        ],
      },
      {
        y: 68,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: false },
          { x: 206, w: 4, visible: false },
          { x: 212, w: 4, visible: false },
        ],
      },
      {
        y: 86,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: false },
          { x: 206, w: 4, visible: false },
          { x: 212, w: 4, visible: false },
        ],
      },
      {
        y: 104,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: false },
          { x: 206, w: 4, visible: false },
          { x: 212, w: 4, visible: false },
        ],
      },
      {
        y: 122,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: false },
          { x: 206, w: 4, visible: false },
          { x: 212, w: 4, visible: false },
        ],
      },
      {
        y: 140,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: false },
          { x: 206, w: 4, visible: false },
          { x: 212, w: 4, visible: false },
        ],
      },
      {
        y: 158,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: false },
          { x: 206, w: 4, visible: false },
          { x: 212, w: 4, visible: false },
        ],
      },
    ],
    rowContentWidths: [128, 96, 112, 128, 96, 112, 128],
    rowLabelWidths: [64, 48, 80, 64, 48, 80, 64],
    activeTab: 68,
  },
  {
    highlightX: 39,
    highlightWidth: 18,
    searchTags: [
      { x: 12, width: 16 },
      { x: 30, width: 24 },
      { x: 56, width: 16 },
    ],
    filterChips: [
      {
        y: 50,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: true },
          { x: 206, w: 4, visible: true },
          { x: 212, w: 4, visible: true },
        ],
      },
      {
        y: 68,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: false },
          { x: 206, w: 4, visible: true },
          { x: 212, w: 4, visible: true },
        ],
      },
      {
        y: 86,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: false },
          { x: 206, w: 4, visible: true },
          { x: 212, w: 4, visible: true },
        ],
      },
      {
        y: 104,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: true },
          { x: 206, w: 4, visible: true },
          { x: 212, w: 4, visible: true },
        ],
      },
      {
        y: 122,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: false },
          { x: 206, w: 4, visible: true },
          { x: 212, w: 4, visible: true },
        ],
      },
      {
        y: 140,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: false },
          { x: 206, w: 4, visible: true },
          { x: 212, w: 4, visible: true },
        ],
      },
      {
        y: 158,
        chips: [
          { x: 220, w: 12, visible: true },
          { x: 200, w: 4, visible: true },
          { x: 206, w: 4, visible: true },
          { x: 212, w: 4, visible: true },
        ],
      },
    ],
    rowContentWidths: [112, 128, 96, 112, 128, 96, 112],
    rowLabelWidths: [80, 64, 48, 80, 64, 48, 80],
    activeTab: 40,
  },
  {
    highlightX: 67,
    highlightWidth: 18,
    searchTags: [
      { x: 12, width: 16 },
      { x: 30, width: 20 },
      { x: 52, width: 16 },
      { x: 70, width: 24 },
      { x: 96, width: 16 },
    ],
    filterChips: [
      { y: 50, chips: [{ x: 220, w: 12, visible: true }] },
      { y: 68, chips: [{ x: 220, w: 12, visible: true }] },
      { y: 86, chips: [{ x: 220, w: 12, visible: true }] },
      { y: 104, chips: [{ x: 220, w: 12, visible: true }] },
      { y: 122, chips: [{ x: 220, w: 12, visible: true }] },
      { y: 140, chips: [{ x: 220, w: 12, visible: true }] },
      { y: 158, chips: [{ x: 220, w: 12, visible: true }] },
    ],
    rowContentWidths: [96, 112, 128, 96, 112, 128, 96],
    rowLabelWidths: [48, 80, 64, 48, 80, 64, 48],
    activeTab: 10,
  },
];

export default {
  name: 'IntroductionAnimation',
  data() {
    return {
      frame: 0,
    };
  },
  computed: {
    currentFrame() {
      return frames[this.frame];
    },
    normalizedSearchTags() {
      const allPositions = [
        { x: 12, width: 16 },
        { x: 30, width: 20 },
        { x: 52, width: 16 },
        { x: 70, width: 24 },
        { x: 96, width: 16 },
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
    normalizedFilterChips() {
      const rowYPositions = [50, 68, 86, 104, 122, 140, 158];
      const chipXPositions = [220, 200, 206, 212];
      const chipWidths = [12, 4, 4, 4];

      return rowYPositions.map((y, rowIdx) => {
        const currentRow = this.currentFrame.filterChips[rowIdx];
        return {
          y,
          chips: chipXPositions.map((x, chipIdx) => {
            const currentChip = currentRow.chips[chipIdx];
            return {
              x,
              w: chipWidths[chipIdx],
              visible: currentChip ? currentChip.visible : false,
            };
          }),
        };
      });
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
      <!-- Border -->
      <rect x="0.5" y="0.5" width="239" height="169" rx="7.5" stroke="#BFBFC3" />

      <!-- Animated filter chips -->
      <g v-for="(row, rowIdx) in normalizedFilterChips" :key="`row-${rowIdx}`">
        <rect
          v-for="(chip, chipIdx) in row.chips"
          :key="`chip-${rowIdx}-${chipIdx}`"
          :x="chip.x"
          :y="row.y"
          :width="chip.w"
          height="4"
          rx="2"
          fill="#DCDCDE"
          :style="{ opacity: chip.visible ? 1 : 0 }"
          class="animated-chip"
        />
      </g>

      <!-- Row content bars (animated left side) -->
      <rect
        v-for="(width, idx) in currentFrame.rowContentWidths"
        :key="`content-${idx}`"
        x="8"
        :y="50 + idx * 18"
        :width="width"
        height="4"
        rx="2"
        fill="#DCDCDE"
        class="animated-element"
      />

      <!-- Row labels (animated gray text on left) -->
      <rect
        v-for="(width, idx) in currentFrame.rowLabelWidths"
        :key="`label-${idx}`"
        x="8"
        :y="44 + idx * 18"
        :width="width"
        height="4"
        rx="2"
        fill="#BFBFC3"
        class="animated-element"
      />

      <!-- Search bar -->
      <rect x="8.5" y="26.5" width="179" height="9" rx="4.5" stroke="#BFBFC3" />

      <!-- Search icon -->
      <path
        fill-rule="evenodd"
        clip-rule="evenodd"
        d="M180.466 28C181.828 28 182.931 29.1039 182.931 30.4657C182.931 31.0081 182.756 31.5092 182.459 31.9164L183.888 33.3451C184.037 33.4949 184.037 33.7379 183.888 33.8877C183.738 34.0374 183.495 34.0374 183.345 33.8877L181.916 32.459C181.509 32.7558 181.008 32.9314 180.466 32.9314C179.104 32.9314 178 31.8275 178 30.4657C178 29.1039 179.104 28 180.466 28ZM180.466 28.7673C179.528 28.7673 178.767 29.5276 178.767 30.4657C178.767 31.4038 179.528 32.1641 180.466 32.1641C181.404 32.1641 182.164 31.4038 182.164 30.4657C182.164 29.5276 181.404 28.7673 180.466 28.7673Z"
        fill="#BFBFC3"
      />

      <!-- Animated search tags -->
      <rect
        v-for="(tag, idx) in normalizedSearchTags"
        :key="`tag-${idx}`"
        :x="tag.x"
        y="29"
        :width="tag.width"
        height="4"
        rx="2"
        fill="#626168"
        :style="{ opacity: tag.visible ? 1 : 0 }"
        class="animated-tag"
      />

      <!-- Filter buttons -->
      <rect x="190.5" y="26.5" width="9" height="9" rx="4.5" stroke="#BFBFC3" />
      <rect x="202.5" y="26.5" width="29" height="9" rx="4.5" stroke="#BFBFC3" />

      <!-- Top right button -->
      <rect x="208" y="4" width="24" height="10" rx="5" fill="#DCDCDE" />

      <!-- Divider line -->
      <path
        d="M8 17.5C8 17.2239 8.22386 17 8.5 17H231.5C231.776 17 232 17.2239 232 17.5C232 17.7761 231.776 18 231.5 18H8.5C8.22386 18 8 17.7761 8 17.5Z"
        fill="#DCDCDE"
      />

      <!-- Top tabs -->
      <path
        d="M136 9C136 7.89543 136.895 7 138 7H146C147.105 7 148 7.89543 148 9C148 10.1046 147.105 11 146 11H138C136.895 11 136 10.1046 136 9Z"
        fill="#BFBFC3"
      />
      <path
        d="M131 6C131.207 6 131.375 6.16789 131.375 6.375V8.625H133.625C133.832 8.625 134 8.79289 134 9C134 9.20711 133.832 9.375 133.625 9.375H131.375V11.625C131.375 11.8321 131.207 12 131 12C130.793 12 130.625 11.8321 130.625 11.625V9.375H128.375C128.168 9.375 128 9.20711 128 9C128 8.79289 128.168 8.625 128.375 8.625H130.625V6.375C130.625 6.16789 130.793 6 131 6Z"
        fill="#BFBFC3"
      />
      <path
        d="M98 9C98 7.89543 98.8954 7 100 7H112C113.105 7 114 7.89543 114 9C114 10.1046 113.105 11 112 11H100C98.8954 11 98 10.1046 98 9Z"
        fill="#BFBFC3"
      />

      <!-- Animated tabs -->
      <path
        d="M68 9C68 7.89543 68.8954 7 70 7H82C83.1046 7 84 7.89543 84 9C84 10.1046 83.1046 11 82 11H70C68.8954 11 68 10.1046 68 9Z"
        :fill="currentFrame.activeTab === 10 ? '#626168' : '#BFBFC3'"
        class="animated-element"
      />
      <path
        d="M40 9C40 7.89543 40.8954 7 42 7H54C55.1046 7 56 7.89543 56 9C56 10.1046 55.1046 11 54 11H42C40.8954 11 40 10.1046 40 9Z"
        :fill="currentFrame.activeTab === 40 ? '#626168' : '#BFBFC3'"
        class="animated-element"
      />
      <path
        d="M10 9C10 7.89543 10.8954 7 12 7H24C25.1046 7 26 7.89543 26 9C26 10.1046 25.1046 11 24 11H12C10.8954 11 10 10.1046 10 9Z"
        :fill="currentFrame.activeTab === 68 ? '#626168' : '#BFBFC3'"
        class="animated-element"
      />

      <!-- Animated blue highlight bar -->
      <rect
        :x="currentFrame.highlightX"
        y="16"
        :width="currentFrame.highlightWidth"
        height="2"
        rx="1"
        fill="#1F75CB"
        class="animated-element"
      />
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
    opacity 1.2s ease-out;
}

.animated-chip {
  transition:
    x 0.6s ease-in-out,
    width 0.6s ease-in-out,
    opacity 0.6s ease-in-out;
}
</style>
