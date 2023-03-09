import { mount } from '@vue/test-utils';
import { trimText } from 'helpers/text_helper';
import CompareDropdownLayout from '~/diffs/components/compare_dropdown_layout.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

const TEST_COMMIT_TEXT = '1 commit';
const TEST_CREATED_AT = '2018-10-23T11:49:16.611Z';

describe('CompareDropdownLayout', () => {
  let wrapper;

  const createVersion = ({ id, isHead, isBase, selected, commitsText, createdAt }) => ({
    id,
    href: `version/${id}`,
    versionName: `version ${id}`,
    isHead,
    isBase,
    short_commit_sha: `abcdef${id}`,
    commitsText,
    created_at: createdAt,
    selected,
  });

  const createComponent = (propsData = {}) => {
    wrapper = mount(CompareDropdownLayout, {
      propsData: {
        ...propsData,
      },
    });
  };

  const findListItems = () => wrapper.findAll('li');
  const findListItemsData = () =>
    findListItems().wrappers.map((listItem) => ({
      href: listItem.find('a').attributes('href'),
      text: trimText(listItem.text()),
      createdAt: listItem.findAllComponents(TimeAgo).wrappers[0]?.props('time'),
      isActive: listItem.classes().includes('is-active'),
    }));

  describe('with versions', () => {
    beforeEach(() => {
      const versions = [
        createVersion({
          id: 1,
          isHead: false,
          isBase: true,
          selected: true,
          commitsText: TEST_COMMIT_TEXT,
          createdAt: TEST_CREATED_AT,
        }),
        createVersion({ id: 2, isHead: true, isBase: false, selected: false }),
        createVersion({ id: 3, isHead: false, isBase: false, selected: false }),
      ];

      createComponent({ versions });
    });

    it('renders the selected version name', () => {
      expect(wrapper.text()).toContain('version 1');
    });

    it('renders versions in order', () => {
      expect(findListItemsData()).toEqual([
        {
          href: 'version/1',
          text: 'version 1 (base) abcdef1 1 commit 1 year ago',
          createdAt: TEST_CREATED_AT,
          isActive: true,
        },
        {
          href: 'version/2',
          text: 'version 2 (HEAD) abcdef2',
          createdAt: undefined,
          isActive: false,
        },
        {
          href: 'version/3',
          text: 'version 3 abcdef3',
          createdAt: undefined,
          isActive: false,
        },
      ]);
    });
  });
});
