import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import AutoMergeFailedComponent from '~/vue_merge_request_widget/components/states/mr_widget_auto_merge_failed.vue';
import eventHub from '~/vue_merge_request_widget/event_hub';

describe('MRWidgetAutoMergeFailed', () => {
  let wrapper;
  const mergeError = 'This is the merge error';
  const findButton = () => wrapper.find(GlButton);

  const createComponent = (props = {}, mergeRequestWidgetGraphql = false) => {
    wrapper = shallowMount(AutoMergeFailedComponent, {
      propsData: { ...props },
      data() {
        if (mergeRequestWidgetGraphql) {
          return { mergeError: props.mr?.mergeError };
        }

        return {};
      },
      provide: {
        glFeatures: { mergeRequestWidgetGraphql },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  [true, false].forEach((mergeRequestWidgetGraphql) => {
    describe(`when graphql is ${mergeRequestWidgetGraphql ? 'enabled' : 'dislabed'}`, () => {
      beforeEach(() => {
        createComponent(
          {
            mr: { mergeError },
          },
          mergeRequestWidgetGraphql,
        );
      });

      it('renders failed message', () => {
        expect(wrapper.text()).toContain('This merge request failed to be merged automatically');
      });

      it('renders merge error provided', () => {
        expect(wrapper.text()).toContain(mergeError);
      });

      it('render refresh button', () => {
        expect(findButton().text()).toBe('Refresh');
      });

      it('emits event and shows loading icon when button is clicked', async () => {
        jest.spyOn(eventHub, '$emit');
        findButton().vm.$emit('click');

        expect(eventHub.$emit.mock.calls[0][0]).toBe('MRWidgetUpdateRequested');

        await nextTick();

        expect(findButton().attributes('disabled')).toBe('true');
        expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      });
    });
  });
});
