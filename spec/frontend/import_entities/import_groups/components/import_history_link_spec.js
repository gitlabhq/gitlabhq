import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';

import ImportHistoryLink from '~/import_entities/import_groups/components/import_history_link.vue';

describe('import history link', () => {
  let wrapper;

  const mockHistoryPath = '/import/history';

  const createComponent = ({ props } = {}) => {
    wrapper = shallowMount(ImportHistoryLink, {
      propsData: {
        historyPath: mockHistoryPath,
        ...props,
      },
    });
  };

  const findGlLink = () => wrapper.findComponent(GlLink);

  it('renders link with href', () => {
    const mockId = 174;

    createComponent({
      props: {
        id: mockId,
      },
    });

    expect(findGlLink().text()).toBe('View details');
    expect(findGlLink().attributes('href')).toBe('/import/history?bulk_import_id=174');
  });
});
