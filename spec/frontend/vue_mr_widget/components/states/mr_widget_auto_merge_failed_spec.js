import { shallowMount } from '@vue/test-utils';
import { GlLoadingIcon } from '@gitlab/ui';
import AutoMergeFailedComponent from '~/vue_merge_request_widget/components/states/mr_widget_auto_merge_failed.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';

describe('MRWidgetAutoMergeFailed', () => {
  let wrapper;
  const mergeError = 'This is the merge error';
  const findButton = () => wrapper.find('button');

  const createComponent = (props = {}) => {
    wrapper = shallowMount(AutoMergeFailedComponent, {
      propsData: { ...props },
    });
  };

  beforeEach(() => {
    createComponent({
      mr: { mergeError },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders failed message', () => {
    expect(wrapper.text()).toContain('This merge request failed to be merged automatically');
  });

  it('renders merge error provided', () => {
    expect(wrapper.text()).toContain(mergeError);
  });

  it('render refresh button', () => {
    expect(findButton().text()).toEqual('Refresh');
  });

  it('emits event and shows loading icon when button is clicked', () => {
    jest.spyOn(eventHub, '$emit');
    findButton().trigger('click');

    expect(eventHub.$emit.mock.calls[0][0]).toBe('MRWidgetUpdateRequested');

    return wrapper.vm.$nextTick(() => {
      expect(findButton().attributes('disabled')).toEqual('disabled');
      expect(
        findButton()
          .find(GlLoadingIcon)
          .exists(),
      ).toBe(true);
    });
  });
});
