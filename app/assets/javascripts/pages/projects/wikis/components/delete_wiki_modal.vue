<script>
import _ from 'underscore';
import { GlModal, GlModalDirective } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  components: {
    GlModal,
  },
  directives: {
    'gl-modal': GlModalDirective,
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
    modalId() {
      return 'delete-wiki-modal';
    },
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
  <div class="d-inline-block">
    <button v-gl-modal="modalId" type="button" class="btn btn-danger">{{ __('Delete') }}</button>
    <gl-modal
      :title="title"
      :ok-title="s__('WikiPageConfirmDelete|Delete page')"
      :modal-id="modalId"
      title-tag="h4"
      ok-variant="danger"
      @ok="onSubmit"
    >
      {{ message }}
      <form ref="form" :action="deleteWikiUrl" method="post" class="js-requires-input">
        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
      </form>
    </gl-modal>
  </div>
</template>
