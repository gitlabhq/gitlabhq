import { shallowMount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';

import ImportHistoryLink from '~/import_entities/import_groups/components/import_history_link.vue';

describe('import history link', () => {
  let wrapper;

  const mockHistoryPath = '/import/:id/history';

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMount(ImportHistoryLink, {
      propsData: {
        historyPath: mockHistoryPath,
        ...props,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  it('renders link with href', () => {
    const mockId = 174;

    createComponent({
      props: {
        id: mockId,
      },
    });

    expect(findButton().text()).toBe('Migration details');
    expect(findButton().attributes('href')).toBe('/import/174/history');
  });
});
