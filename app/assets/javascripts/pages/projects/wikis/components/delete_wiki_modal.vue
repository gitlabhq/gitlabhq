<script>
import GlModal from '~/vue_shared/components/gl_modal.vue';
  import { s__} from '~/locale';

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
    csrfToken: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    text() {
      return s__('WikiPageConfirmDelete|Are you sure you want to delete this page?')
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
    :header-title-text="s__('WikiPageConfirmDelete|Delete Wiki?')"
    footer-primary-button-variant="danger"
    :footer-primary-button-text="s__('WikiPageConfirmDelete|Delete')"
    @submit="onSubmit"
  >
    {{ text }}

    <form
        ref="form"
        :action="deleteWikiUrl"
        method="post"
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
      </form>
  </gl-modal>
</template>

