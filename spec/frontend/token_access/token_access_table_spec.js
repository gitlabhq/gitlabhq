import { GlButton, GlTableLite } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import TokenAccessTable from '~/token_access/components/token_access_table.vue';
import { mockGroups, mockProjects, mockFields } from './mock_data';

describe('Token access table', () => {
  let wrapper;

  const createComponent = (props) => {
    wrapper = mountExtended(TokenAccessTable, {
      provide: {
        fullPath: 'root/ci-project',
      },
      propsData: {
        ...props,
      },
    });
  };

  const findTable = () => wrapper.findComponent(GlTableLite);
  const findDeleteButton = () => wrapper.findComponent(GlButton);
  const findAllTableRows = () => wrapper.findAllByTestId('token-access-table-row');
  const findIcon = (type) => wrapper.findByTestId(`token-access-${type}-icon`);
  const findProjectAvatar = (type) => wrapper.findByTestId(`token-access-${type}-avatar`);
  const findName = (type) => wrapper.findByTestId(`token-access-${type}-name`);

  describe.each`
    type         | isGroup  | items
    ${'group'}   | ${true}  | ${mockGroups}
    ${'project'} | ${false} | ${mockProjects}
  `('when provided with $type', ({ type, isGroup, items }) => {
    beforeEach(() => {
      createComponent({
        isGroup,
        items,
        tableFields: mockFields,
      });
    });

    it('displays a table', () => {
      expect(findTable().exists()).toBe(true);
    });

    it('displays the correct amount of table rows', () => {
      expect(findAllTableRows(type)).toHaveLength(items.length);
    });

    it('delete button emits event with correct item to delete', async () => {
      await findDeleteButton().trigger('click');

      expect(wrapper.emitted('removeItem')).toEqual([[items[0]]]);
    });

    it('displays icon and avatar', () => {
      expect(findIcon(type).props('name')).toBe(type);
      expect(findProjectAvatar(type).props('projectName')).toBe(items[0].name);
    });

    it('displays fullpath as a link to the project', () => {
      expect(findName(type).text()).toBe(items[0].fullPath);
      expect(findName(type).attributes('href')).toBe(`/${items[0].fullPath}`);
    });
  });
});
