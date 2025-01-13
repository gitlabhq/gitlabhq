import { createWrapper } from '@vue/test-utils';

import initDeleteTagModal from '~/tags/init_delete_tag_modal';
import DeleteTagModal from '~/tags/components/delete_tag_modal.vue';

describe('initDeleteTagModal', () => {
  let appRoot;
  let wrapper;

  const createAppRoot = () => {
    appRoot = document.createElement('div');
    appRoot.setAttribute('class', 'js-delete-tag-modal');
    document.body.appendChild(appRoot);

    wrapper = createWrapper(initDeleteTagModal());
  };

  afterEach(() => {
    if (appRoot) {
      appRoot.remove();
      appRoot = null;
    }
  });

  const findDeleteTagModal = () => wrapper.findComponent(DeleteTagModal);

  describe('when there is no app root', () => {
    it('returns false', () => {
      expect(initDeleteTagModal()).toBe(false);
    });
  });

  describe('when there is an app root', () => {
    beforeEach(() => {
      createAppRoot();
    });

    it('renders the modal', () => {
      expect(findDeleteTagModal().exists()).toBe(true);
    });
  });
});
