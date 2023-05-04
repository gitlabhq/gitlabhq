import { mount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import NewBoardButton from '~/boards/components/new_board_button.vue';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { stubExperiments } from 'helpers/experimentation_helper';
import eventHub from '~/boards/eventhub';

const FEATURE = 'prominent_create_board_btn';

describe('NewBoardButton', () => {
  let wrapper;

  const createComponent = (args = {}) =>
    extendedWrapper(
      mount(NewBoardButton, {
        provide: {
          canAdminBoard: true,
          multipleIssueBoardsAvailable: true,
          ...args,
        },
      }),
    );

  describe('control variant', () => {
    beforeAll(() => {
      stubExperiments({ [FEATURE]: 'control' });
    });

    it('renders nothing', () => {
      wrapper = createComponent();

      expect(wrapper.text()).toBe('');
    });
  });

  describe('candidate variant', () => {
    beforeAll(() => {
      stubExperiments({ [FEATURE]: 'candidate' });
    });

    it('renders New board button when `candidate` variant', () => {
      wrapper = createComponent();

      expect(wrapper.text()).toBe('New board');
    });

    it('renders nothing when `canAdminBoard` is `false`', () => {
      wrapper = createComponent({ canAdminBoard: false });

      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });

    it('renders nothing when `multipleIssueBoardsAvailable` is `false`', () => {
      wrapper = createComponent({ multipleIssueBoardsAvailable: false });

      expect(wrapper.findComponent(GlButton).exists()).toBe(false);
    });

    it('emits `showBoardModal` when button is clicked', () => {
      jest.spyOn(eventHub, '$emit').mockImplementation();

      wrapper = createComponent();

      wrapper.findComponent(GlButton).vm.$emit('click', { preventDefault: () => {} });

      expect(eventHub.$emit).toHaveBeenCalledWith('showBoardModal', 'new');
    });
  });
});
