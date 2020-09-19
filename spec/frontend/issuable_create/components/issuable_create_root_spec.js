import { mount } from '@vue/test-utils';

import IssuableCreateRoot from '~/issuable_create/components/issuable_create_root.vue';
import IssuableForm from '~/issuable_create/components/issuable_form.vue';

const createComponent = ({
  descriptionPreviewPath = '/gitlab-org/gitlab-shell/preview_markdown',
  descriptionHelpPath = '/help/user/markdown',
  labelsFetchPath = '/gitlab-org/gitlab-shell/-/labels.json',
  labelsManagePath = '/gitlab-org/gitlab-shell/-/labels',
} = {}) => {
  return mount(IssuableCreateRoot, {
    propsData: {
      descriptionPreviewPath,
      descriptionHelpPath,
      labelsFetchPath,
      labelsManagePath,
    },
    slots: {
      title: `
        <h1 class="js-create-title">New Issuable</h1>
      `,
      actions: `
        <button class="js-issuable-save">Submit issuable</button>
      `,
    },
  });
};

describe('IssuableCreateRoot', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    it('renders component container element with class "issuable-create-container"', () => {
      expect(wrapper.classes()).toContain('issuable-create-container');
    });

    it('renders contents for slot "title"', () => {
      const titleEl = wrapper.find('h1.js-create-title');

      expect(titleEl.exists()).toBe(true);
      expect(titleEl.text()).toBe('New Issuable');
    });

    it('renders issuable-form component', () => {
      expect(wrapper.find(IssuableForm).exists()).toBe(true);
    });

    it('renders contents for slot "actions" within issuable-form component', () => {
      const buttonEl = wrapper.find(IssuableForm).find('button.js-issuable-save');

      expect(buttonEl.exists()).toBe(true);
      expect(buttonEl.text()).toBe('Submit issuable');
    });
  });
});
