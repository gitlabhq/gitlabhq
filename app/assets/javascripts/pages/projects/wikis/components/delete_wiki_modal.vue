<script>
import _ from 'underscore';
import GlModal from '~/vue_shared/components/gl_modal.vue';
import { s__, sprintf } from '~/locale';

export default {
  components: {
    GlModal,
  },
  props: {
    deleteWikiUrl: {
      type: String,
      required: true,
      default: '',
    },
    pageTitle: {
      type: String,
      required: true,
      default: '',
    },
    csrfToken: {
      type: String,
      required: true,
      default: '',
    },
  },
  computed: {
    message() {
      return s__('WikiPageConfirmDelete|Are you sure you want to delete this page?');
    },
    title() {
      return sprintf(
        s__('WikiPageConfirmDelete|Delete page %{pageTitle}?'),
        {
          pageTitle: _.escape(this.pageTitle),
        },
        false,
      );
    },
  },
  methods: {
    onSubmit() {
      this.$refs.form.submit();
    },
  },
};
</script>

<template>
  <gl-modal
    id="delete-wiki-modal"
    :header-title-text="title"
    :footer-primary-button-text="s__('WikiPageConfirmDelete|Delete page')"
    footer-primary-button-variant="danger"
    @submit="onSubmit"
  >
    {{ message }}
    <form
      ref="form"
      :action="deleteWikiUrl"
      method="post"
      class="js-requires-input"
    >
      <input
        ref="method"
        type="hidden"
        name="_method"
        value="delete"
      />
      <input
        :value="csrfToken"
        type="hidden"
        name="authenticity_token"
      />
    </form>
  </gl-modal>
</template>
