import { shallowMount } from '@vue/test-utils';

import InvalidContentMessage from '~/static_site_editor/components/invalid_content_message.vue';

describe('~/static_site_editor/components/invalid_content_message.vue', () => {
  let wrapper;
  const findDocumentationButton = () => wrapper.find({ ref: 'documentationButton' });
  const documentationUrl =
    'https://gitlab.com/gitlab-org/project-templates/static-site-editor-middleman';

  beforeEach(() => {
    wrapper = shallowMount(InvalidContentMessage);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the configuration button link', () => {
    expect(findDocumentationButton().exists()).toBe(true);
    expect(findDocumentationButton().attributes('href')).toBe(documentationUrl);
  });
});
