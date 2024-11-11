import { mountExtended } from 'helpers/vue_test_utils_helper';
import HtmlPresenter from '~/glql/components/presenters/html.vue';

describe('HtmlPresenter', () => {
  it('renders html using v-safe-html', () => {
    const wrapper = mountExtended(HtmlPresenter, {
      propsData: {
        data: '<strong>this is html including emoji: <gl-emoji>:smile:</gl-emoji></strong><script>var a = "this will be removed"</script>',
      },
    });

    expect(wrapper.html()).toBe(
      '<div><strong>this is html including emoji: <gl-emoji>:smile:</gl-emoji></strong></div>',
    );
  });
});
