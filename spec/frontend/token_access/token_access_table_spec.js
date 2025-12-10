import { GlBadge, GlTable, GlLoadingIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import TokenAccessTable from '~/token_access/components/token_access_table.vue';
import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { mockGroups, mockProjects } from './mock_data';

describe('Token access table', () => {
  let wrapper;

  const createComponent = (props, provided) => {
    wrapper = mountExtended(TokenAccessTable, {
      provide: { fullPath: 'root/ci-project2', ...provided },
      propsData: props,
      directives: {
        GlTooltip: createMockDirective('gl-tooltip'),
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findCurrentProjectBadge = () => wrapper.findComponent(GlBadge);
  const findEditButton = () => wrapper.findByTestId('token-access-table-edit-button');
  const findRemoveButton = () => wrapper.findByTestId('token-access-table-remove-button');
  const findAllTableRows = () => findTable().findAll('tbody tr');
  const findIcon = () => wrapper.findByTestId('token-access-icon');
  const findProjectAvatar = () => wrapper.findByTestId('token-access-avatar');
  const findName = () => wrapper.findByTestId('token-access-name');
  const findPolicies = () => findAllTableRows().at(0).findAll('td').at(1);
  const findLoadingMessage = () => wrapper.findByTestId('loading-message');

  describe.each`
    type         | items
    ${'group'}   | ${mockGroups}
    ${'project'} | ${mockProjects}
  `('when provided with $type', ({ type, items }) => {
    beforeEach(() => {
      createComponent({ items, loading: false });
    });

    it('displays the table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('displays the correct amount of table rows', () => {
      expect(findAllTableRows(type)).toHaveLength(items.length);
    });

    it('displays icon and avatar', () => {
      expect(findIcon().props('name')).toBe(type);
      expect(findProjectAvatar().props('projectName')).toBe(items[0].name);
    });

    it(`displays link to the ${type}`, () => {
      expect(findName(type).text()).toBe(items[0].fullPath);
      expect(findName(type).attributes('href')).toBe(items[0].webUrl);
    });

    describe.each`
      buttonName  | findButton          | icon        | tooltip               | eventName
      ${'edit'}   | ${findEditButton}   | ${'pencil'} | ${'Edit permissions'} | ${'editItem'}
      ${'remove'} | ${findRemoveButton} | ${'remove'} | ${'Remove access'}    | ${'removeItem'}
    `('$buttonName button', ({ findButton, icon, tooltip, eventName }) => {
      it('shows button', () => {
        expect(findButton().props('icon')).toBe(icon);
      });

      it('shows button tooltip', () => {
        expect(getBinding(findButton().element, 'gl-tooltip').value).toBe(tooltip);
      });

      it('emits event when button is clicked', async () => {
        await findButton().trigger('click');

        expect(wrapper.emitted(eventName)[0][0]).toBe(items[0]);
      });
    });

    it('does not show the current project badge', () => {
      expect(findCurrentProjectBadge().exists()).toBe(false);
    });
  });

  describe('when item is the current project', () => {
    beforeEach(() =>
      createComponent({ items: [mockProjects.at(-1)] }, { fullPath: 'root/ci-project' }),
    );

    it('shows the edit button', () => {
      expect(findEditButton().exists()).toBe(true);
    });

    it('shows the current project badge', () => {
      expect(findCurrentProjectBadge().text()).toBe('Current project');
    });

    it('does not show remove button', () => {
      expect(findRemoveButton().exists()).toBe(false);
    });
  });

  describe('when table is loading', () => {
    it('shows loading icon', () => {
      createComponent({ items: mockGroups, loading: true });

      expect(findTable().findComponent(GlLoadingIcon).props('size')).toBe('md');
      expect(findLoadingMessage().exists()).toBe(false);
    });

    it('shows loading message when available', () => {
      createComponent({
        items: mockGroups,
        loading: true,
        loadingMessage: 'Removing auto-populated entries...',
      });

      expect(findLoadingMessage().text()).toBe('Removing auto-populated entries...');
    });
  });

  describe('policies column', () => {
    it('shows policies when items has policies', () => {
      createComponent({ items: [mockGroups[0]] });

      expect(findPolicies().findAll('li').at(0).text()).toBe('Read to Jobs');
      expect(findPolicies().findAll('li').at(1).text()).toBe('Read and write to Deployments');
    });

    it('shows default text when item has default permissions selected', () => {
      createComponent({ items: [mockGroups[1]] });

      expect(findPolicies().text()).toBe('User membership and role');
    });

    it('shows minimal text when items has no policies', () => {
      createComponent({ items: [mockGroups[2]] });

      expect(findPolicies().text()).toBe('No resources selected (minimal access only)');
    });
  });
});
