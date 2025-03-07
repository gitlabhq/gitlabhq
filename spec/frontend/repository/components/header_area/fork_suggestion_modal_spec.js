import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ForkSuggestionModal from '~/repository/components/header_area/fork_suggestion_modal.vue';

const DEFAULT_PROPS = { visible: true, forkPath: '/fork/project/path' };

describe('ForkSuggestionModal component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ForkSuggestionModal, {
      propsData: { ...DEFAULT_PROPS, ...props },
      stubs: {
        GlModal,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findMessage = () => wrapper.findByTestId('message');

  beforeEach(() => {
    createComponent();
  });

  it('sets correct modal visibility', () => {
    createComponent({ visible: false });
    expect(findModal().props('visible')).toBe(false);
  });

  it('renders the modal with correct variant', () => {
    expect(findModal().exists()).toBe(true);
    expect(findMessage().text()).toBe(
      "You're not allowed to make changes to this project directly. Create a fork to make changes and submit a merge request.",
    );
  });

  describe('reactivity to prop changes', () => {
    it('updates the fork path when forkPath prop changes', () => {
      createComponent({ forkPath: '/new/fork/path' });

      expect(findModal().props('actionPrimary')).toMatchObject({
        attributes: {
          href: '/new/fork/path',
        },
      });
    });
  });
});
