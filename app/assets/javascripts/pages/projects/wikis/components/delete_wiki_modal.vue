<script>
import _ from 'underscore';
import GlModal from '~/vue_shared/components/gl_modal.vue';
import { s__, sprintf } from '~/locale';

export default {
  components: {
    GlModal
  },
  props: {
    deleteWikiUrl: {
      type: String,
      required: false,
      default: '',
    },
    pageTitle: {
      type: String,
      required: false,
      default: '',
    },
    csrfToken: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    message() {
     return  sprintf(s__('WikiPageConfirmDelete|Delete %{pageTitle}'),
        {
          pageTitle: _.escape(this.pageTitle),
        },
        false,
      );
    },

    title() {
      return  sprintf(s__('WikiPageConfirmDelete|Delete Page %{pageTitle}?'),
        {
          pageTitle: `'${_.escape(this.pageTitle)}'`,
        },
        false,
      );
    }
  },
  methods: {
    onSubmit() {
      this.$refs.form.submit();
    }
  }
}
</script>

<template>
  <gl-modal
    id="delete-wiki-modal"
    :header-title-text="title"
    footer-primary-button-variant="danger"
    :footer-primary-button-text="s__('WikiPageConfirmDelete|Delete Page')"
    @submit="onSubmit"
  >
    <form
        ref="form"
        :action="deleteWikiUrl"
        method="post"
        class="form-horizontal js-requires-input"
      >
        <input
          ref="method"
          type="hidden"
          name="_method"
          value="delete"
        />
        <input
          type="hidden"
          name="authenticity_token"
          :value="csrfToken"
        />

        <div class="form-group">
          <div class="col-sm-12">
              <label for="commit_message" class="control-label-full-width">Commit Message</label>
            </div>
          <div class="col-sm-12">
            <div class="commit-message-container">
              <textarea
                id="commit_message"
                rows="3"
                name="commit_message"
                :value="message"
                class="form-control js-commit-message" required></textarea>
            </div>
            
          </div>
        </div>
        <div class="form-group">
          <div class="col-sm-12">
            <label for="branch_name" class="control-label-full-width">Target Branch</label>
          </div>
          <div class="col-sm-12">
            <input type="text" name="branch_name" class="form-control js-commit-message ref-name" required />
          </div>
        </div>
      </form>
  </gl-modal>
</template>

