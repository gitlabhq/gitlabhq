import { mount } from '@vue/test-utils';

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import IssuableCreateRoot from '~/vue_shared/issuable/create/components/issuable_create_root.vue';
import IssuableForm from '~/vue_shared/issuable/create/components/issuable_form.vue';
import { TYPE_TEST_CASE } from '~/issues/constants';

Vue.use(VueApollo);

const createComponent = ({
  descriptionPreviewPath = '/gitlab-org/gitlab-shell/preview_markdown',
  descriptionHelpPath = '/help/user/markdown',
  labelsFetchPath = '/gitlab-org/gitlab-shell/-/labels.json',
  labelsManagePath = '/gitlab-org/gitlab-shell/-/labels',
  issuableType = TYPE_TEST_CASE,
} = {}) => {
  return mount(IssuableCreateRoot, {
    propsData: {
      descriptionPreviewPath,
      descriptionHelpPath,
      labelsFetchPath,
      labelsManagePath,
      issuableType,
    },
    apolloProvider: createMockApollo(),
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
      expect(wrapper.findComponent(IssuableForm).exists()).toBe(true);
    });

    it('renders contents for slot "actions" within issuable-form component', () => {
      const buttonEl = wrapper.findComponent(IssuableForm).find('button.js-issuable-save');

      expect(buttonEl.exists()).toBe(true);
      expect(buttonEl.text()).toBe('Submit issuable');
    });
  });
});
