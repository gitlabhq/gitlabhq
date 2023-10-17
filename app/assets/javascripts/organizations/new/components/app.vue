<script>
import { GlSprintf, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import { helpPagePath } from '~/helpers/help_page_helper';
import createOrganizationMutation from '../graphql/mutations/create_organization.mutation.graphql';
import NewEditForm from '../../shared/components/new_edit_form.vue';

export default {
  name: 'OrganizationNewApp',
  components: { NewEditForm, GlSprintf, GlLink },
  i18n: {
    pageTitle: s__('Organization|New organization'),
    pageDescription: s__(
      'Organization|%{linkStart}Organizations%{linkEnd} are a top-level container to hold your groups and projects.',
    ),
    errorMessage: s__('Organization|An error occurred creating an organization. Please try again.'),
  },
  data() {
    return {
      loading: false,
    };
  },
  computed: {
    organizationsHelpPagePath() {
      return helpPagePath('user/organization/index');
    },
  },
  methods: {
    async onSubmit(formValues) {
      this.loading = true;
      try {
        const {
          data: {
            createOrganization: { organization, errors },
          },
        } = await this.$apollo.mutate({
          mutation: createOrganizationMutation,
          variables: {
            ...formValues,
          },
        });

        if (errors.length) {
          // TODO: handle errors when using real API after https://gitlab.com/gitlab-org/gitlab/-/issues/417891 is complete.
          return;
        }

        visitUrl(organization.path);
      } catch (error) {
        createAlert({ message: this.$options.i18n.errorMessage, error, captureError: true });
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <div class="gl-py-6">
    <h1 class="gl-mt-0 gl-font-size-h-display">{{ $options.i18n.pageTitle }}</h1>
    <p>
      <gl-sprintf :message="$options.i18n.pageDescription">
        <template #link="{ content }"
          ><gl-link :href="organizationsHelpPagePath">{{ content }}</gl-link></template
        >
      </gl-sprintf>
    </p>
    <new-edit-form :loading="loading" @submit="onSubmit" />
  </div>
</template>
