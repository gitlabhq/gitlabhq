import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlCollapsibleListbox, GlSkeletonLoader, GlLink } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import WorkItemDescriptionTemplateListbox from '~/work_items/components/work_item_description_template_listbox.vue';
import descriptionTemplatesListQuery from '~/work_items/graphql/work_item_description_templates_list.query.graphql';

Vue.use(VueApollo);

const mockTemplatesList = [
  {
    name: 'template 1',
    __typename: 'WorkItemDescriptionTemplate',
    category: 'GROUP A',
    projectId: 1,
  },
  {
    name: 'template 2',
    __typename: 'WorkItemDescriptionTemplate',
    category: 'GROUP A',
    projectId: 2,
  },
  {
    name: 'template 3',
    __typename: 'WorkItemDescriptionTemplate',
    category: 'GROUP B',
    projectId: 3,
  },
  {
    name: 'Bug',
    __typename: 'WorkItemDescriptionTemplate',
    category: 'GROUP C',
    projectId: 4,
  },
  {
    name: 'template 1',
    __typename: 'WorkItemDescriptionTemplate',
    category: 'GROUP C',
    projectId: 1,
  },
];

const mockDescriptionTemplatesResult = {
  data: {
    namespace: {
      __typename: 'Namespace',
      id: 'gid://gitlab/Project/1',
      workItemDescriptionTemplates: {
        __typename: 'WorkItemDescriptionTemplateConnection',
        nodes: mockTemplatesList,
      },
    },
  },
};

const mockEmptyDescriptionTemplatesResult = {
  data: {
    namespace: {
      __typename: 'Namespace',
      id: 'gid://gitlab/Project/1',
      workItemDescriptionTemplates: {
        __typename: 'WorkItemDescriptionTemplateConnection',
        nodes: [],
      },
    },
  },
};

describe('WorkItemDescriptionTemplateListbox', () => {
  let wrapper;
  let handler;

  const createComponent = ({
    template,
    templatesResult = mockDescriptionTemplatesResult,
    canReset = true,
  } = {}) => {
    handler = jest.fn().mockResolvedValue(templatesResult);
    wrapper = mountExtended(WorkItemDescriptionTemplateListbox, {
      apolloProvider: createMockApollo([[descriptionTemplatesListQuery, handler]]),
      propsData: {
        fullPath: 'gitlab-org/gitlab',
        template,
        canReset,
      },
    });
  };

  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findSkeletonLoader = () => wrapper.findComponent(GlSkeletonLoader);
  const findTemplateMessage = () => wrapper.findByTestId('template-message');
  const findTemplateMessageLink = () => wrapper.findComponent(GlLink);
  const findClearButton = () => wrapper.findByTestId('clear-template');
  const findResetButton = () => wrapper.findByTestId('reset-template');

  it('displays a skeleton loader', () => {
    createComponent();
    expect(findSkeletonLoader().exists()).toBe(true);
  });

  describe('when the templates have been fetched', () => {
    it('does not display a skeleton loader', async () => {
      createComponent();
      await waitForPromises();
      expect(findSkeletonLoader().exists()).toBe(false);
    });

    describe('and there are templates to display', () => {
      describe('and there is no template already selected', () => {
        beforeEach(async () => {
          createComponent();
          await waitForPromises();
        });

        it('renders a collapsible-listbox component', () => {
          expect(findListbox().exists()).toBe(true);
        });

        it('displays "Choose a template" by default', () => {
          expect(findListbox().text()).toContain('Choose a template');
        });

        it('displays a header in the listbox that says "Select template"', () => {
          expect(findListbox().text()).toContain('Select template');
        });
      });

      describe('when there is already a template selected', () => {
        beforeEach(async () => {
          createComponent({
            template: mockTemplatesList[0],
          });
          await waitForPromises();
        });

        it('displays the template name in the listbox', () => {
          expect(findListbox().text()).toContain(mockTemplatesList[0].name);
        });
      });

      describe('when the listbox is opened', () => {
        beforeEach(async () => {
          createComponent();
          await waitForPromises();
          findListbox().vm.$emit('shown');
          await nextTick();
        });

        it('displays a list of templates', () => {
          const text = findListbox().text();
          for (const template of mockTemplatesList) {
            expect(text).toContain(template.name);
          }
        });

        it('displays group names for the templates', () => {
          const text = findListbox().text();
          expect(text).toContain('GROUP A');
          expect(text).toContain('GROUP B');
          expect(text).toContain('GROUP C');
        });

        it('allows case insensitive searching to narrow down results', async () => {
          // only matches 'Bug'
          findListbox().vm.$emit('search', 'bug');
          await nextTick();
          expect(findListbox().props('items')).toHaveLength(1);
        });

        describe('clear selected template', () => {
          it('displays a "no template" button', () => {
            expect(findClearButton().text()).toBe('No template');
          });

          it('emits a "clear" event when the "no template" button is clicked', async () => {
            await findClearButton().vm.$emit('click');

            expect(wrapper.emitted('clear')).toHaveLength(1);
          });
        });

        describe('resetting selected template', () => {
          it('displays a "reset template" button', () => {
            expect(findResetButton().text()).toBe('Reset template');
          });

          it('emits a "reset" event when the "reset template" button is clicked', async () => {
            await findResetButton().vm.$emit('click');

            expect(wrapper.emitted('reset')).toHaveLength(1);
          });
        });
      });

      describe('when a template is selected from the list', () => {
        const { name, category, projectId } = mockTemplatesList[0];

        beforeEach(async () => {
          createComponent();
          await waitForPromises();
          findListbox().vm.$emit('shown');
          findListbox().vm.$emit('select', JSON.stringify({ name, category, projectId }));
        });

        it('emits the selected template', () => {
          expect(wrapper.emitted('selectTemplate')).toEqual([[{ name, category, projectId }]]);
        });
      });
    });

    describe('but there are no templates to display', () => {
      beforeEach(async () => {
        createComponent({ templatesResult: mockEmptyDescriptionTemplatesResult });
        await waitForPromises();
      });
      it('displays a message about adding description templates', () => {
        expect(findTemplateMessage().text()).toMatchInterpolatedText(
          'Add description templates to help your contributors communicate effectively!',
        );
      });
      it('displays a link to the docs', () => {
        expect(findTemplateMessageLink().attributes('href')).toBe(
          '/help/user/project/description_templates',
        );
      });
    });
  });
});
