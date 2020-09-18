import { shallowMount } from '@vue/test-utils';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import WebIdeLink from '~/vue_shared/components/web_ide_link.vue';
import ActionsButton from '~/vue_shared/components/actions_button.vue';

const TEST_WEB_IDE_URL = '/-/ide/project/gitlab-test/test/edit/master/-/';
const TEST_GITPOD_URL = 'https://gitpod.test/';

const ACTION_WEB_IDE = {
  href: TEST_WEB_IDE_URL,
  key: 'webide',
  secondaryText: 'Quickly and easily edit multiple files in your project.',
  tooltip: '',
  text: 'Web IDE',
  attrs: {
    'data-qa-selector': 'web_ide_button',
  },
};
const ACTION_WEB_IDE_FORK = {
  ...ACTION_WEB_IDE,
  href: '#modal-confirm-fork',
  handle: expect.any(Function),
};
const ACTION_GITPOD = {
  href: TEST_GITPOD_URL,
  key: 'gitpod',
  secondaryText: 'Launch a ready-to-code development environment for your project.',
  tooltip: 'Launch a ready-to-code development environment for your project.',
  text: 'Gitpod',
  attrs: {
    'data-qa-selector': 'gitpod_button',
  },
};
const ACTION_GITPOD_ENABLE = {
  ...ACTION_GITPOD,
  href: '#modal-enable-gitpod',
  handle: expect.any(Function),
};

describe('Web IDE link component', () => {
  let wrapper;

  function createComponent(props) {
    wrapper = shallowMount(WebIdeLink, {
      propsData: {
        webIdeUrl: TEST_WEB_IDE_URL,
        gitpodUrl: TEST_GITPOD_URL,
        ...props,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  const findActionsButton = () => wrapper.find(ActionsButton);
  const findLocalStorageSync = () => wrapper.find(LocalStorageSync);

  it.each`
    props                                                                        | expectedActions
    ${{}}                                                                        | ${[ACTION_WEB_IDE]}
    ${{ webIdeIsFork: true }}                                                    | ${[{ ...ACTION_WEB_IDE, text: 'Edit fork in Web IDE' }]}
    ${{ needsToFork: true }}                                                     | ${[ACTION_WEB_IDE_FORK]}
    ${{ showWebIdeButton: false, showGitpodButton: true, gitpodEnabled: true }}  | ${[ACTION_GITPOD]}
    ${{ showWebIdeButton: false, showGitpodButton: true, gitpodEnabled: false }} | ${[ACTION_GITPOD_ENABLE]}
    ${{ showGitpodButton: true, gitpodEnabled: false }}                          | ${[ACTION_WEB_IDE, ACTION_GITPOD_ENABLE]}
  `('renders actions with props=$props', ({ props, expectedActions }) => {
    createComponent(props);

    expect(findActionsButton().props('actions')).toEqual(expectedActions);
  });

  describe('with multiple actions', () => {
    beforeEach(() => {
      createComponent({ showWebIdeButton: true, showGitpodButton: true, gitpodEnabled: true });
    });

    it('selected Web IDE by default', () => {
      expect(findActionsButton().props()).toMatchObject({
        actions: [ACTION_WEB_IDE, ACTION_GITPOD],
        selectedKey: ACTION_WEB_IDE.key,
      });
    });

    it('should set selection with local storage value', async () => {
      expect(findActionsButton().props('selectedKey')).toBe(ACTION_WEB_IDE.key);

      findLocalStorageSync().vm.$emit('input', ACTION_GITPOD.key);

      await wrapper.vm.$nextTick();

      expect(findActionsButton().props('selectedKey')).toBe(ACTION_GITPOD.key);
    });

    it('should update local storage when selection changes', async () => {
      expect(findLocalStorageSync().props('value')).toBe(ACTION_WEB_IDE.key);

      findActionsButton().vm.$emit('select', ACTION_GITPOD.key);

      await wrapper.vm.$nextTick();

      expect(findActionsButton().props('selectedKey')).toBe(ACTION_GITPOD.key);
      expect(findLocalStorageSync().props('value')).toBe(ACTION_GITPOD.key);
    });
  });
});
