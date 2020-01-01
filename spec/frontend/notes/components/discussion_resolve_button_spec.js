import { createLocalVue, shallowMount } from '@vue/test-utils';
import resolveDiscussionButton from '~/notes/components/discussion_resolve_button.vue';

const buttonTitle = 'Resolve discussion';

describe('resolveDiscussionButton', () => {
  let wrapper;
  let localVue;

  const factory = options => {
    localVue = createLocalVue();
    wrapper = shallowMount(resolveDiscussionButton, {
      localVue,
      ...options,
    });
  };

  beforeEach(() => {
    factory({
      propsData: {
        isResolving: false,
        buttonTitle,
      },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should emit a onClick event on button click', () => {
    const button = wrapper.find({ ref: 'button' });

    button.trigger('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted()).toEqual({
        onClick: [[]],
      });
    });
  });

  it('should contain the provided button title', () => {
    const button = wrapper.find({ ref: 'button' });

    expect(button.text()).toContain(buttonTitle);
  });

  it('should show a loading spinner while resolving', () => {
    factory({
      propsData: {
        isResolving: true,
        buttonTitle,
      },
    });

    const button = wrapper.find({ ref: 'isResolvingIcon' });

    expect(button.exists()).toEqual(true);
  });

  it('should only show a loading spinner while resolving', () => {
    factory({
      propsData: {
        isResolving: false,
        buttonTitle,
      },
    });

    const button = wrapper.find({ ref: 'isResolvingIcon' });

    localVue.nextTick(() => {
      expect(button.exists()).toEqual(false);
    });
  });
});
