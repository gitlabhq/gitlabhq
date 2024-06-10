import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PageHeading from '~/vue_shared/components/page_heading.vue';

describe('Pagination links component', () => {
  const actionsTemplate = `
    <template #actions>
      Actions go here
    </template>
  `;

  const descriptionTemplate = `
    <template #actions>
      Description go here
    </template>
  `;

  describe('Ordered Layout', () => {
    let wrapper;

    const createWrapper = () => {
      wrapper = shallowMountExtended(PageHeading, {
        scopedSlots: {
          actions: actionsTemplate,
          description: descriptionTemplate,
        },
        propsData: {
          heading: 'Page heading',
        },
      });
    };

    const heading = () => wrapper.findByTestId('page-heading');
    const actions = () => wrapper.findByTestId('page-heading-actions');
    const description = () => wrapper.findByTestId('page-heading-description');

    beforeEach(() => {
      createWrapper();
    });

    describe('rendering', () => {
      it('renders the correct heading', () => {
        expect(heading().text()).toBe('Page heading');
        expect(heading().classes()).toEqual(['gl-heading-1', '!gl-m-0']);
        expect(heading().element.tagName.toLowerCase()).toBe('h1');
      });

      it('renders its action slot content', () => {
        expect(actions().text()).toBe('Actions go here');
      });

      it('renders its description slot content', () => {
        expect(description().text()).toBe('Description go here');
        expect(description().classes()).toEqual(['gl-w-full', 'gl-mt-2', 'gl-text-secondary']);
      });
    });
  });
});
