import { shallowMount } from '@vue/test-utils';
import { GlBadge } from '@gitlab/ui';
import ImportHistoryStatusBadge from '~/vue_shared/components/import/import_history_status_badge.vue';

describe('ImportHistoryStatusBadge', () => {
  let wrapper;

  const createComponent = (propsData = {}) => {
    wrapper = shallowMount(ImportHistoryStatusBadge, {
      propsData,
    });
  };

  const findBadge = () => wrapper.findComponent(GlBadge);

  it.each`
    status        | variant      | icon                | text
    ${'started'}  | ${'warning'} | ${'status-running'} | ${'In progress'}
    ${'finished'} | ${'success'} | ${'status-success'} | ${'Complete'}
    ${'failed'}   | ${'danger'}  | ${'status-failed'}  | ${'Failed'}
    ${'timeout'}  | ${'danger'}  | ${'status-failed'}  | ${'Failed'}
    ${'created'}  | ${'neutral'} | ${'status-waiting'} | ${'Not started'}
  `(
    'renders the badge with correct props for status=$status',
    ({ status, variant, icon, text }) => {
      createComponent({
        status,
      });

      const badge = findBadge();
      expect(badge.props()).toMatchObject({
        variant,
        icon,
      });
      expect(badge.text()).toBe(text);
    },
  );
});
