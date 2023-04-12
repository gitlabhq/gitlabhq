import { mount, shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlTable } from '@gitlab/ui';

import PaginationBar from '~/vue_shared/components/pagination_bar/pagination_bar.vue';
import ImportDetailsTable from '~/import/details/components/import_details_table.vue';

describe('Import details table', () => {
  let wrapper;

  const createComponent = ({ mountFn = shallowMount } = {}) => {
    wrapper = mountFn(ImportDetailsTable);
  };

  const findGlTable = () => wrapper.findComponent(GlTable);
  const findGlEmptyState = () => findGlTable().findComponent(GlEmptyState);
  const findPaginationBar = () => wrapper.findComponent(PaginationBar);

  describe('template', () => {
    describe('when no items are available', () => {
      it('renders table with empty state', () => {
        createComponent({ mountFn: mount });

        expect(findGlEmptyState().exists()).toBe(true);
      });

      it('does not render pagination', () => {
        createComponent();

        expect(findPaginationBar().exists()).toBe(false);
      });
    });
  });
});
