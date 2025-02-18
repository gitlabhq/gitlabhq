import { GlTable, GlLoadingIcon } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import TokenAccessTable from '~/token_access/components/token_access_table.vue';
import { mockGroups, mockProjects } from './mock_data';

describe('Token access table', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = mountExtended(TokenAccessTable, {
      provide: { fullPath: 'root/ci-project' },
      propsData: props,
    });
  };

  const findTable = () => wrapper.findComponent(GlTable);
  const findEditButton = () => wrapper.findByTestId('token-access-table-edit-button');
  const findRemoveButton = () => wrapper.findByTestId('token-access-table-remove-button');
  const findAllTableRows = () => findTable().findAll('tbody tr');
  const findIcon = () => wrapper.findByTestId('token-access-icon');
  const findProjectAvatar = () => wrapper.findByTestId('token-access-avatar');
  const findName = () => wrapper.findByTestId('token-access-name');
  const findPolicies = () => findAllTableRows().at(0).findAll('td').at(1);
  const findAutopopulatedIcon = () => wrapper.findByTestId('autopopulated-icon');

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

    it('remove button emits event with correct item to remove', async () => {
      await findRemoveButton().trigger('click');

      expect(wrapper.emitted('removeItem')).toEqual([[items[0]]]);
    });

    it('displays icon and avatar', () => {
      expect(findIcon().props('name')).toBe(type);
      expect(findProjectAvatar().props('projectName')).toBe(items[0].name);
    });

    it(`displays link to the ${type}`, () => {
      expect(findName(type).text()).toBe(items[0].fullPath);
      expect(findName(type).attributes('href')).toBe(items[0].webUrl);
    });

    describe('edit button', () => {
      it('shows button', () => {
        expect(findEditButton().props('icon')).toBe('pencil');
      });

      it('emits editItem event when button is clicked', () => {
        findEditButton().vm.$emit('click');

        expect(wrapper.emitted('editItem')[0][0]).toBe(items[0]);
      });
    });
  });

  describe('when item is the current project', () => {
    beforeEach(() => createComponent({ items: [mockProjects.at(-1)] }));

    it('does not show edit button', () => {
      expect(findEditButton().exists()).toBe(false);
    });

    it('does not show remove button', () => {
      expect(findRemoveButton().exists()).toBe(false);
    });
  });

  describe('when table is loading', () => {
    it('shows loading icon', () => {
      createComponent({ items: mockGroups, loading: true });

      expect(findTable().findComponent(GlLoadingIcon).props('size')).toBe('md');
    });
  });

  describe('policies column', () => {
    it('shows policies when items has policies', () => {
      createComponent({ items: [mockGroups[0]] });

      expect(findPolicies().findAll('li').at(0).text()).toBe('Read to Jobs');
      expect(findPolicies().findAll('li').at(1).text()).toBe('Read and write to Containers');
    });

    it('shows default text when item has default permissions selected', () => {
      createComponent({ items: [mockGroups[1]] });

      expect(findPolicies().text()).toBe('Default (user membership and role)');
    });

    it('shows minimal text when items has no policies', () => {
      createComponent({ items: [mockGroups[2]] });

      expect(findPolicies().text()).toBe('No resources selected (minimal access only)');
    });
  });

  describe('when showPolicies prop is false', () => {
    beforeEach(() => createComponent({ showPolicies: false, items: mockGroups }));

    it('does not show policies column', () => {
      const tableFieldKeys = findTable()
        .props('fields')
        .map(({ key }) => key);

      expect(tableFieldKeys).not.toContain('policies');
    });

    it('does not show edit button', () => {
      expect(findEditButton().exists()).toBe(false);
    });
  });

  describe('group auto-populated icon', () => {
    it('shows the icon when the item is auto-populated', () => {
      createComponent({ items: [mockGroups[0]] });

      expect(findAutopopulatedIcon().exists()).toBe(true);
    });

    it('does no shows the icon when the item is not auto-populated', () => {
      createComponent({ items: [mockGroups[2]] });

      expect(findAutopopulatedIcon().exists()).toBe(false);
    });
  });

  describe('project auto-populated icon', () => {
    it('shows the icon when the item is auto-populated', () => {
      createComponent({ items: [mockProjects[0]] });

      expect(findAutopopulatedIcon().exists()).toBe(true);
    });

    it('does no shows the icon when the item is not auto-populated', () => {
      createComponent({ items: [mockProjects[1]] });

      expect(findAutopopulatedIcon().exists()).toBe(false);
    });
  });
});
