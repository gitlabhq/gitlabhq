import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ReportWidgetContainer from '~/vue_merge_request_widget/components/report_widget_container.vue';

describe('app/assets/javascripts/vue_merge_request_widget/components/report_widget_container.vue', () => {
  let wrapper;

  const createComponent = ({ slot } = {}) => {
    wrapper = mountExtended(ReportWidgetContainer, {
      slots: {
        default: slot,
      },
    });
  };

  it('hides the container when children has no content', async () => {
    createComponent({ slot: `<span><b></b></span>` });
    await nextTick();
    expect(wrapper.isVisible()).toBe(false);
  });

  it('hides the container when children has only empty spaces', async () => {
    createComponent({ slot: `<span><b>&nbsp;<br/>\t\r\n</b></span>&nbsp;` });
    await nextTick();
    expect(wrapper.isVisible()).toBe(false);
  });

  it('shows the container when a child has content', async () => {
    createComponent({ slot: `<span><b>test</b></span>` });
    await nextTick();
    expect(wrapper.isVisible()).toBe(true);
  });
});
