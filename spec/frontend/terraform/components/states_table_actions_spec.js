import { GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StateActions from '~/terraform/components/states_table_actions.vue';

describe('StatesTableActions', () => {
  let wrapper;

  const defaultProps = {
    state: {
      id: 'gid/1',
      name: 'state-1',
      latestVersion: { downloadPath: '/path' },
    },
  };

  const createComponent = (propsData = defaultProps) => {
    wrapper = shallowMount(StateActions, {
      propsData,
      stubs: { GlDropdown },
    });

    return wrapper.vm.$nextTick();
  };

  const findDownloadBtn = () => wrapper.find('[data-testid="terraform-state-download"]');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when state has a latestVersion', () => {
    beforeEach(() => {
      return createComponent();
    });

    it('displays a download button', () => {
      const downloadBtn = findDownloadBtn();

      expect(downloadBtn.text()).toBe('Download JSON');
    });
  });

  describe('when state does not have a latestVersion', () => {
    beforeEach(() => {
      return createComponent({
        state: {
          id: 'gid/1',
          name: 'state-1',
          latestVersion: null,
        },
      });
    });

    it('does not display a download button', () => {
      expect(findDownloadBtn().exists()).toBe(false);
    });
  });
});
