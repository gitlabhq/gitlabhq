<script>
  import animateMixin from '../mixins/animate';

  export default {
    mixins: [animateMixin],
    data() {
      return {
        preAnimation: false,
        pulseAnimation: false,
        titleEl: document.querySelector('title'),
      };
    },
    props: {
      issuableRef: {
        type: String,
        required: true,
      },
      titleHtml: {
        type: String,
        required: true,
      },
      titleText: {
        type: String,
        required: true,
      },
    },
    watch: {
      titleHtml() {
        this.setPageTitle();
        this.animateChange();
      },
    },
    methods: {
      setPageTitle() {
        const currentPageTitleScope = this.titleEl.innerText.split('·');
        currentPageTitleScope[0] = `${this.titleText} (${this.issuableRef}) `;
        this.titleEl.textContent = currentPageTitleScope.join('·');
      },
    },
  };
</script>

<template>
  <h2
    class="title"
    :class="{
      'issue-realtime-pre-pulse': preAnimation,
      'issue-realtime-trigger-pulse': pulseAnimation
    }"
    v-html="titleHtml"
  >
  </h2>
</template>
