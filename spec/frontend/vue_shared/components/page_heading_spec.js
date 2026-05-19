import { merge } from 'lodash-es';
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

  const headingTemplate = `
    <template #heading>
      Heading with custom elements <i>here</i>
    </template>
  `;

  describe('Ordered Layout', () => {
    let wrapper;

    const createWrapper = (options = {}) => {
      wrapper = shallowMountExtended(
        PageHeading,
        merge(
          {
            scopedSlots: {
              actions: actionsTemplate,
              description: descriptionTemplate,
            },
            propsData: {
              heading: 'Page heading',
            },
          },
          options,
        ),
      );
    };

    const heading = () => wrapper.findByTestId('page-heading');
    const actions = () => wrapper.findByTestId('page-heading-actions');
    const description = () => wrapper.findByTestId('page-heading-description');

    describe('basic rendering', () => {
      it('renders the correct heading', () => {
        createWrapper();

        expect(heading().text()).toBe('Page heading');
        expect(heading().classes()).toEqual(expect.arrayContaining(['gl-heading-1', '!gl-m-0']));
        expect(heading().element.tagName.toLowerCase()).toBe('h1');
      });

      it('renders its action slot content', () => {
        createWrapper();

        expect(actions().text()).toBe('Actions go here');
      });

      it('renders its description slot content', () => {
        createWrapper();

        expect(description().text()).toBe('Description go here');
        expect(description().classes()).toEqual(
          expect.arrayContaining(['gl-w-full', 'gl-text-subtle']),
        );
      });

      it('renders the heading slot if provided', () => {
        createWrapper({ scopedSlots: { heading: headingTemplate } });

        expect(heading().text()).toBe('Heading with custom elements here');
      });
    });

    describe('heading levels', () => {
      it('renders heading as h2 when headingTag prop is h2', () => {
        createWrapper({ propsData: { headingTag: 'h2' } });

        expect(heading().element.tagName.toLowerCase()).toBe('h2');
        expect(heading().text()).toBe('Page heading');
        expect(heading().classes()).toEqual(expect.arrayContaining(['gl-heading-1', '!gl-m-0']));
      });

      it('renders heading as h2 when headingTag is injected as h2', () => {
        createWrapper({ provide: { panelHeadingTag: 'h2' } });

        expect(heading().element.tagName.toLowerCase()).toBe('h2');
      });

      it('prop headingTag overrides injected headingTag', () => {
        createWrapper({
          propsData: { headingTag: 'h1' },
          provide: { panelHeadingTag: 'h2' },
        });

        expect(heading().element.tagName.toLowerCase()).toBe('h1');
      });
    });
  });
});
