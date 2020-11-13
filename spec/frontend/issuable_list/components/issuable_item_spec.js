import { shallowMount } from '@vue/test-utils';
import { GlLink, GlLabel, GlIcon, GlFormCheckbox } from '@gitlab/ui';

import IssuableItem from '~/issuable_list/components/issuable_item.vue';
import IssuableAssignees from '~/vue_shared/components/issue/issue_assignees.vue';

import { mockIssuable, mockRegularLabel, mockScopedLabel } from '../mock_data';

const createComponent = ({ issuableSymbol = '#', issuable = mockIssuable, slots = {} } = {}) =>
  shallowMount(IssuableItem, {
    propsData: {
      issuableSymbol,
      issuable,
      enableLabelPermalinks: true,
      showDiscussions: true,
      showCheckbox: false,
    },
    slots,
  });

describe('IssuableItem', () => {
  const mockLabels = mockIssuable.labels.nodes;
  const mockAuthor = mockIssuable.author;
  const originalUrl = gon.gitlab_url;
  let wrapper;

  beforeEach(() => {
    gon.gitlab_url = 'http://0.0.0.0:3000';
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    gon.gitlab_url = originalUrl;
  });

  describe('computed', () => {
    describe('author', () => {
      it('returns `issuable.author` reference', () => {
        expect(wrapper.vm.author).toEqual(mockIssuable.author);
      });
    });

    describe('authorId', () => {
      it.each`
        authorId                 | returnValue
        ${1}                     | ${1}
        ${'1'}                   | ${1}
        ${'gid://gitlab/User/1'} | ${1}
        ${'foo'}                 | ${null}
      `(
        'returns $returnValue when value of `issuable.author.id` is $authorId',
        async ({ authorId, returnValue }) => {
          wrapper.setProps({
            issuable: {
              ...mockIssuable,
              author: {
                ...mockAuthor,
                id: authorId,
              },
            },
          });

          await wrapper.vm.$nextTick();

          expect(wrapper.vm.authorId).toBe(returnValue);
        },
      );
    });

    describe('isIssuableUrlExternal', () => {
      it.each`
        issuableWebUrl                                             | urlType                    | returnValue
        ${'/gitlab-org/gitlab-test/-/issues/2'}                    | ${'relative'}              | ${false}
        ${'http://0.0.0.0:3000/gitlab-org/gitlab-test/-/issues/1'} | ${'absolute and internal'} | ${false}
        ${'http://jira.atlassian.net/browse/IG-1'}                 | ${'external'}              | ${true}
        ${'https://github.com/gitlabhq/gitlabhq/issues/1'}         | ${'external'}              | ${true}
      `(
        'returns $returnValue when `issuable.webUrl` is $urlType',
        async ({ issuableWebUrl, returnValue }) => {
          wrapper.setProps({
            issuable: {
              ...mockIssuable,
              webUrl: issuableWebUrl,
            },
          });

          await wrapper.vm.$nextTick();

          expect(wrapper.vm.isIssuableUrlExternal).toBe(returnValue);
        },
      );
    });

    describe('labels', () => {
      it('returns `issuable.labels.nodes` reference when it is available', () => {
        expect(wrapper.vm.labels).toEqual(mockLabels);
      });

      it('returns `issuable.labels` reference when it is available', async () => {
        wrapper.setProps({
          issuable: {
            ...mockIssuable,
            labels: mockLabels,
          },
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.labels).toEqual(mockLabels);
      });

      it('returns empty array when none of `issuable.labels.nodes` or `issuable.labels` are available', async () => {
        wrapper.setProps({
          issuable: {
            ...mockIssuable,
            labels: null,
          },
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.labels).toEqual([]);
      });
    });

    describe('assignees', () => {
      it('returns `issuable.assignees` reference when it is available', () => {
        expect(wrapper.vm.assignees).toBe(mockIssuable.assignees);
      });
    });

    describe('createdAt', () => {
      it('returns string containing timeago string based on `issuable.createdAt`', () => {
        expect(wrapper.vm.createdAt).toContain('created');
        expect(wrapper.vm.createdAt).toContain('ago');
      });
    });

    describe('updatedAt', () => {
      it('returns string containing timeago string based on `issuable.updatedAt`', () => {
        expect(wrapper.vm.updatedAt).toContain('updated');
        expect(wrapper.vm.updatedAt).toContain('ago');
      });
    });

    describe('showDiscussions', () => {
      it.each`
        userDiscussionsCount | returnValue
        ${0}                 | ${true}
        ${1}                 | ${true}
        ${undefined}         | ${false}
        ${null}              | ${false}
      `(
        'returns $returnValue when issuable.userDiscussionsCount is $userDiscussionsCount',
        ({ userDiscussionsCount, returnValue }) => {
          const wrapperWithDiscussions = createComponent({
            issuableSymbol: '#',
            issuable: {
              ...mockIssuable,
              userDiscussionsCount,
            },
          });

          expect(wrapperWithDiscussions.vm.showDiscussions).toBe(returnValue);

          wrapperWithDiscussions.destroy();
        },
      );
    });
  });

  describe('methods', () => {
    describe('scopedLabel', () => {
      it.each`
        label               | labelType    | returnValue
        ${mockRegularLabel} | ${'regular'} | ${false}
        ${mockScopedLabel}  | ${'scoped'}  | ${true}
      `(
        'return $returnValue when provided label param is a $labelType label',
        ({ label, returnValue }) => {
          expect(wrapper.vm.scopedLabel(label)).toBe(returnValue);
        },
      );
    });

    describe('labelTitle', () => {
      it.each`
        label               | propWithTitle | returnValue
        ${{ title: 'foo' }} | ${'title'}    | ${'foo'}
        ${{ name: 'foo' }}  | ${'name'}     | ${'foo'}
      `('returns string value of `label.$propWithTitle`', ({ label, returnValue }) => {
        expect(wrapper.vm.labelTitle(label)).toBe(returnValue);
      });
    });

    describe('labelTarget', () => {
      it('returns target string for a provided label param when `enableLabelPermalinks` is true', () => {
        expect(wrapper.vm.labelTarget(mockRegularLabel)).toBe(
          '?label_name%5B%5D=Documentation%20Update',
        );
      });

      it('returns string "#" for a provided label param when `enableLabelPermalinks` is false', async () => {
        wrapper.setProps({
          enableLabelPermalinks: false,
        });

        await wrapper.vm.$nextTick();

        expect(wrapper.vm.labelTarget(mockRegularLabel)).toBe('#');
      });
    });
  });

  describe('template', () => {
    it('renders issuable title', () => {
      const titleEl = wrapper.find('[data-testid="issuable-title"]');

      expect(titleEl.exists()).toBe(true);
      expect(titleEl.find(GlLink).attributes('href')).toBe(mockIssuable.webUrl);
      expect(titleEl.find(GlLink).attributes('target')).not.toBeDefined();
      expect(titleEl.find(GlLink).text()).toBe(mockIssuable.title);
    });

    it('renders checkbox when `showCheckbox` prop is true', async () => {
      wrapper.setProps({
        showCheckbox: true,
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.find(GlFormCheckbox).exists()).toBe(true);
      expect(wrapper.find(GlFormCheckbox).attributes('checked')).not.toBeDefined();

      wrapper.setProps({
        checked: true,
      });

      await wrapper.vm.$nextTick();

      expect(wrapper.find(GlFormCheckbox).attributes('checked')).toBe('true');
    });

    it('renders issuable title with `target` set as "_blank" when issuable.webUrl is external', async () => {
      wrapper.setProps({
        issuable: {
          ...mockIssuable,
          webUrl: 'http://jira.atlassian.net/browse/IG-1',
        },
      });

      await wrapper.vm.$nextTick();

      expect(
        wrapper
          .find('[data-testid="issuable-title"]')
          .find(GlLink)
          .attributes('target'),
      ).toBe('_blank');
    });

    it('renders issuable reference', () => {
      const referenceEl = wrapper.find('[data-testid="issuable-reference"]');

      expect(referenceEl.exists()).toBe(true);
      expect(referenceEl.text()).toBe(`#${mockIssuable.iid}`);
    });

    it('renders issuable reference via slot', () => {
      const wrapperWithRefSlot = createComponent({
        issuableSymbol: '#',
        issuable: mockIssuable,
        slots: {
          reference: `
            <b class="js-reference">${mockIssuable.iid}</b>
          `,
        },
      });
      const referenceEl = wrapperWithRefSlot.find('.js-reference');

      expect(referenceEl.exists()).toBe(true);
      expect(referenceEl.text()).toBe(`${mockIssuable.iid}`);

      wrapperWithRefSlot.destroy();
    });

    it('renders issuable createdAt info', () => {
      const createdAtEl = wrapper.find('[data-testid="issuable-created-at"]');

      expect(createdAtEl.exists()).toBe(true);
      expect(createdAtEl.attributes('title')).toBe('Jun 29, 2020 1:52pm GMT+0000');
      expect(createdAtEl.text()).toBe(wrapper.vm.createdAt);
    });

    it('renders issuable author info', () => {
      const authorEl = wrapper.find('[data-testid="issuable-author"]');

      expect(authorEl.exists()).toBe(true);
      expect(authorEl.attributes()).toMatchObject({
        'data-user-id': `${wrapper.vm.authorId}`,
        'data-username': mockAuthor.username,
        'data-name': mockAuthor.name,
        'data-avatar-url': mockAuthor.avatarUrl,
        href: mockAuthor.webUrl,
      });
      expect(authorEl.text()).toBe(mockAuthor.name);
    });

    it('renders issuable author info via slot', () => {
      const wrapperWithAuthorSlot = createComponent({
        issuableSymbol: '#',
        issuable: mockIssuable,
        slots: {
          reference: `
            <span class="js-author">${mockAuthor.name}</span>
          `,
        },
      });
      const authorEl = wrapperWithAuthorSlot.find('.js-author');

      expect(authorEl.exists()).toBe(true);
      expect(authorEl.text()).toBe(mockAuthor.name);

      wrapperWithAuthorSlot.destroy();
    });

    it('renders timeframe via slot', () => {
      const wrapperWithTimeframeSlot = createComponent({
        issuableSymbol: '#',
        issuable: mockIssuable,
        slots: {
          timeframe: `
            <b class="js-timeframe">Jan 1, 2020 - Mar 31, 2020</b>
          `,
        },
      });
      const timeframeEl = wrapperWithTimeframeSlot.find('.js-timeframe');

      expect(timeframeEl.exists()).toBe(true);
      expect(timeframeEl.text()).toBe('Jan 1, 2020 - Mar 31, 2020');

      wrapperWithTimeframeSlot.destroy();
    });

    it('renders gl-label component for each label present within `issuable` prop', () => {
      const labelsEl = wrapper.findAll(GlLabel);

      expect(labelsEl.exists()).toBe(true);
      expect(labelsEl).toHaveLength(mockLabels.length);
      expect(labelsEl.at(0).props()).toMatchObject({
        backgroundColor: mockLabels[0].color,
        title: mockLabels[0].title,
        description: mockLabels[0].description,
        scoped: false,
        target: wrapper.vm.labelTarget(mockLabels[0]),
        size: 'sm',
      });
    });

    it('renders issuable status via slot', () => {
      const wrapperWithStatusSlot = createComponent({
        issuableSymbol: '#',
        issuable: mockIssuable,
        slots: {
          status: `
            <b class="js-status">${mockIssuable.state}</b>
          `,
        },
      });
      const statusEl = wrapperWithStatusSlot.find('.js-status');

      expect(statusEl.exists()).toBe(true);
      expect(statusEl.text()).toBe(`${mockIssuable.state}`);

      wrapperWithStatusSlot.destroy();
    });

    it('renders discussions count', () => {
      const discussionsEl = wrapper.find('[data-testid="issuable-discussions"]');

      expect(discussionsEl.exists()).toBe(true);
      expect(discussionsEl.find(GlLink).attributes()).toMatchObject({
        title: 'Comments',
        href: `${mockIssuable.webUrl}#notes`,
      });
      expect(discussionsEl.find(GlIcon).props('name')).toBe('comments');
      expect(discussionsEl.find(GlLink).text()).toContain('2');
    });

    it('renders issuable-assignees component', () => {
      const assigneesEl = wrapper.find(IssuableAssignees);

      expect(assigneesEl.exists()).toBe(true);
      expect(assigneesEl.props()).toMatchObject({
        assignees: mockIssuable.assignees,
        iconSize: 16,
        maxVisible: 4,
      });
    });

    it('renders issuable updatedAt info', () => {
      const updatedAtEl = wrapper.find('[data-testid="issuable-updated-at"]');

      expect(updatedAtEl.exists()).toBe(true);
      expect(updatedAtEl.find('span').attributes('title')).toBe('Sep 10, 2020 11:41am GMT+0000');
      expect(updatedAtEl.text()).toBe(wrapper.vm.updatedAt);
    });
  });
});
