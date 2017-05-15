<script>
  import animateMixin from '../mixins/animate';
  import titleField from './fields/title.vue';

  export default {
    mixins: [animateMixin],
    components: {
      titleField,
    },
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
      formState: {
        type: Object,
        required: true,
      },
      showForm: {
        type: Boolean,
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
  <div>
    <title-field
      v-if="showForm"
      :form-state="formState" />
    <h2
      v-else
      class="title"
      :class="{
        'issue-realtime-pre-pulse': preAnimation,
        'issue-realtime-trigger-pulse': pulseAnimation
      }"
      v-html="titleHtml"
    >
    </h2>
  </div>
</template>
