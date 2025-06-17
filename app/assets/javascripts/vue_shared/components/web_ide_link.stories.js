import getSomeWritableForksResponse from 'test_fixtures/graphql/vue_shared/components/web_ide/get_writable_forks.query.graphql_some.json';
import createMockApollo from 'helpers/mock_apollo_helper';
import getWritableForksQuery from '~/vue_shared/components/web_ide/get_writable_forks.query.graphql';
import WebIdeLink from './web_ide_link.vue';

export default {
  component: WebIdeLink,
  title: 'vue_shared/web_ide_link',
};

const createTemplate = (config = {}) => {
  let { apolloProvider } = config;

  if (apolloProvider == null) {
    const requestHandlers = [
      [getWritableForksQuery, () => Promise.resolve(getSomeWritableForksResponse)],
    ];
    apolloProvider = createMockApollo(requestHandlers);
  }

  return (args, { argTypes }) => ({
    components: { WebIdeLink },
    apolloProvider,
    props: Object.keys(argTypes),
    template: `
      <web-ide-link v-bind="$props" class="gl-w-12">
      </web-ide-link>
    `,
  });
};

const defaultArgs = {
  isFork: false,
  needsToFork: false,
  isGitpodEnabledForUser: true,
  showEditButton: true,
  showWebIdeButton: true,
  isGitpodEnabledForInstance: true,
  showPipelineEditorButton: true,
  disableForkModal: true,
  gitpodUrl: 'http://example.com',
  editUrl: '/edit',
  webIdeUrl: '/ide',
  pipelineEditorUrl: '/pipeline-editor',
};

export const Default = {
  render: createTemplate(),
  args: defaultArgs,
};

export const Blob = {
  render: createTemplate(),
  args: {
    ...defaultArgs,
    isBlob: true,
  },
};

export const WithButtonVariant = {
  render: createTemplate(),
  args: {
    ...defaultArgs,
    buttonVariant: 'confirm',
  },
};

export const Fork = {
  render: createTemplate(),
  args: {
    ...defaultArgs,
    isFork: true,
  },
};

export const NeedsToFork = {
  render: createTemplate(),
  args: {
    ...defaultArgs,
    needsToFork: true,
    needsToForkWithWebIde: true,
    disableForkModal: false,
    forkPath: '/fork',
    forkModalId: 'fork-modal',
    isGitpodEnabledForUser: false,
    showPipelineEditorButton: false,
  },
};

export const WithCustomText = {
  render: createTemplate(),
  args: {
    ...defaultArgs,
    webIdeText: 'Custom Web IDE Text',
    gitpodText: 'Custom Gitpod Text',
  },
};

export const Disabled = {
  render: createTemplate(),
  args: {
    ...defaultArgs,
    disabled: true,
  },
};

export const CustomTooltipText = {
  render: createTemplate(),
  args: {
    ...defaultArgs,
    disabled: true,
    customTooltipText: 'You cannot edit files in read-only repositories',
  },
};

export const WithSlots = {
  render: (args, { argTypes }) => {
    const requestHandlers = [
      [getWritableForksQuery, () => Promise.resolve(getSomeWritableForksResponse)],
    ];
    const apolloProvider = createMockApollo(requestHandlers);

    return {
      components: { WebIdeLink },
      apolloProvider,
      props: Object.keys(argTypes),
      template: `
        <web-ide-link v-bind="$props" class="gl-w-12">
          <template #before-actions>
            <div class="gl-p-4 gl-border-b">Before Actions Content</div>
          </template>
          <template #after-actions>
            <div class="gl-p-4 gl-border-t">After Actions Content</div>
          </template>
        </web-ide-link>
      `,
    };
  },
  args: defaultArgs,
};
