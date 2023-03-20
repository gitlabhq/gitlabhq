import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ForkSuggestion from '~/repository/components/fork_suggestion.vue';

const DEFAULT_PROPS = { forkPath: 'some_file.js/fork' };

describe('ForkSuggestion component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(ForkSuggestion, {
      propsData: { ...DEFAULT_PROPS },
    });
  };

  beforeEach(() => createComponent());

  const { i18n } = ForkSuggestion;
  const findMessage = () => wrapper.findByTestId('message');
  const findForkButton = () => wrapper.findByTestId('fork');
  const findCancelButton = () => wrapper.findByTestId('cancel');

  it('renders a message', () => {
    expect(findMessage().text()).toBe(i18n.message);
  });

  it('renders a Fork button', () => {
    const forkButton = findForkButton();

    expect(forkButton.text()).toBe(i18n.fork);
    expect(forkButton.attributes('href')).toBe(DEFAULT_PROPS.forkPath);
  });

  it('renders a Cancel button', () => {
    expect(findCancelButton().text()).toBe(i18n.cancel);
  });

  it('emits a cancel event when Cancel button is clicked', () => {
    findCancelButton().vm.$emit('click');

    expect(wrapper.emitted('cancel')).toEqual([[]]);
  });
});
