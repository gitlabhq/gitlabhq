import { GlBadge, GlLink, GlLabel, GlIcon, GlFormCheckbox, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { useFakeDate } from 'helpers/fake_date';
import { shallowMountExtended as shallowMount } from 'helpers/vue_test_utils_helper';
import IssuableItem from '~/vue_shared/issuable/list/components/issuable_item.vue';
import WorkItemTypeIcon from '~/work_items/components/work_item_type_icon.vue';
import IssuableAssignees from '~/issuable/components/issue_assignees.vue';

import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import { mockIssuable, mockRegularLabel } from '../mock_data';

const createComponent = ({
  hasScopedLabelsFeature = false,
  issuableSymbol = '#',
  issuable = mockIssuable,
  showCheckbox = true,
  slots = {},
  showWorkItemTypeIcon = false,
  isActive = false,
  preventRedirect = false,
} = {}) =>
  shallowMount(IssuableItem, {
    propsData: {
      hasScopedLabelsFeature,
      issuableSymbol,
      issuable,
      showDiscussions: true,
      showCheckbox,
      showWorkItemTypeIcon,
      isActive,
      preventRedirect,
    },
    slots,
    stubs: {
      GlSprintf,
    },
  });

const MOCK_GITLAB_URL = 'http://0.0.0.0:3000';

describe('IssuableItem', () => {
  // The mock data is dependent that this is after our default date
  useFakeDate(2020, 11, 11);

  const mockLabels = mockIssuable.labels.nodes;
  const mockAuthor = mockIssuable.author;
  let wrapper;

  const findTimestampWrapper = () => wrapper.findByTestId('issuable-timestamp');
  const findWorkItemTypeIcon = () => wrapper.findComponent(WorkItemTypeIcon);
  const findIssuableTitleLink = () => wrapper.findComponentByTestId('issuable-title-link');
  const findIssuableItemWrapper = () => wrapper.findByTestId('issuable-item-wrapper');
  const findStatusEl = () => wrapper.findByTestId('issuable-status');

  beforeEach(() => {
    gon.gitlab_url = MOCK_GITLAB_URL;
  });

  describe('computed', () => {
    describe('author', () => {
      it('returns `issuable.author` reference', () => {
        wrapper = createComponent();

        expect(wrapper.vm.author).toEqual(mockIssuable.author);
      });
    });

    describe('externalAuthor', () => {
      it('returns `externalAuthor` reference', () => {
        wrapper = createComponent();

        expect(wrapper.vm.externalAuthor).toEqual(mockIssuable.externalAuthor);
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
          wrapper = createComponent({
            issuable: {
              ...mockIssuable,
              author: {
                ...mockAuthor,
                id: authorId,
              },
            },
          });

          await nextTick();

          expect(wrapper.vm.authorId).toBe(returnValue);
        },
      );
    });

    describe('isIssuableUrlExternal', () => {
      it.each`
        issuableWebUrl                                            | urlType                    | returnValue
        ${'/gitlab-org/gitlab-test/-/issues/2'}                   | ${'relative'}              | ${false}
        ${`${MOCK_GITLAB_URL}/gitlab-org/gitlab-test/-/issues/1`} | ${'absolute and internal'} | ${false}
        ${'http://jira.atlassian.net/browse/IG-1'}                | ${'external'}              | ${true}
        ${'https://github.com/gitlabhq/gitlabhq/issues/1'}        | ${'external'}              | ${true}
      `(
        'returns $returnValue when `issuable.webUrl` is $urlType',
        async ({ issuableWebUrl, returnValue }) => {
          wrapper = createComponent({
            issuable: {
              ...mockIssuable,
              webUrl: issuableWebUrl,
            },
          });

          await nextTick();

          expect(wrapper.vm.isIssuableUrlExternal).toBe(returnValue);
        },
      );
    });

    describe('labels', () => {
      it('returns `issuable.labels.nodes` reference when it is available', () => {
        wrapper = createComponent();

        expect(wrapper.vm.labels).toEqual(mockLabels);
      });

      it('returns `issuable.labels` reference when it is available', async () => {
        wrapper = createComponent({
          issuable: {
            ...mockIssuable,
            labels: mockLabels,
          },
        });

        await nextTick();

        expect(wrapper.vm.labels).toEqual(mockLabels);
      });

      it('returns empty array when none of `issuable.labels.nodes` or `issuable.labels` are available', async () => {
        wrapper = createComponent({
          issuable: {
            ...mockIssuable,
            labels: null,
          },
        });

        await nextTick();

        expect(wrapper.vm.labels).toEqual([]);
      });
    });

    describe('assignees', () => {
      it('returns `issuable.assignees` reference when it is available', () => {
        wrapper = createComponent();

        expect(wrapper.vm.assignees).toBe(mockIssuable.assignees);
      });
    });

    describe('timestamp', () => {
      it('returns timestamp based on `issuable.updatedAt` when the issue is open', () => {
        wrapper = createComponent();

        expect(findTimestampWrapper().attributes('title')).toBe(
          localeDateFormat.asDateTimeFull.format(mockIssuable.updatedAt),
        );
      });

      it('returns timestamp based on `issuable.closedAt` when the issue is closed', () => {
        const closedAt = '2020-06-18T11:30:00Z';
        wrapper = createComponent({
          issuable: { ...mockIssuable, closedAt, state: 'closed' },
        });

        expect(findTimestampWrapper().attributes('title')).toBe(
          localeDateFormat.asDateTimeFull.format(closedAt),
        );
      });

      it('returns timestamp based on `issuable.updatedAt` when the issue is closed but `issuable.closedAt` is undefined', () => {
        wrapper = createComponent({
          issuable: { ...mockIssuable, closedAt: undefined, state: 'closed' },
        });

        expect(findTimestampWrapper().attributes('title')).toBe(
          localeDateFormat.asDateTimeFull.format(mockIssuable.updatedAt),
        );
      });
    });

    describe('formattedTimestamp', () => {
      it('returns timeago string based on `issuable.updatedAt` when the issue is open', () => {
        wrapper = createComponent();

        expect(findTimestampWrapper().text()).toContain('updated');
        expect(findTimestampWrapper().text()).toContain('ago');
      });

      it('returns timeago string based on `issuable.closedAt` when the issue is closed', () => {
        wrapper = createComponent({
          issuable: { ...mockIssuable, closedAt: '2020-06-18T11:30:00Z', state: 'closed' },
        });

        expect(findTimestampWrapper().text()).toContain('closed');
        expect(findTimestampWrapper().text()).toContain('ago');
      });

      it('returns timeago string based on `issuable.updatedAt` when the issue is closed but `issuable.closedAt` is undefined', () => {
        wrapper = createComponent({
          issuable: { ...mockIssuable, closedAt: undefined, state: 'closed' },
        });

        expect(findTimestampWrapper().text()).toContain('updated');
        expect(findTimestampWrapper().text()).toContain('ago');
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
          wrapper = createComponent({
            issuableSymbol: '#',
            issuable: {
              ...mockIssuable,
              userDiscussionsCount,
            },
          });

          expect(wrapper.findByTestId('issuable-comments').exists()).toBe(returnValue);
        },
      );
    });
  });

  describe('methods', () => {
    describe('labelTitle', () => {
      it.each`
        label               | propWithTitle | returnValue
        ${{ title: 'foo' }} | ${'title'}    | ${'foo'}
        ${{ name: 'foo' }}  | ${'name'}     | ${'foo'}
      `('returns string value of `label.$propWithTitle`', ({ label, returnValue }) => {
        wrapper = createComponent();

        expect(wrapper.vm.labelTitle(label)).toBe(returnValue);
      });
    });

    describe('labelTarget', () => {
      it('returns target string for a provided label param', () => {
        wrapper = createComponent();

        expect(wrapper.vm.labelTarget(mockRegularLabel)).toBe(
          '?label_name[]=Documentation%20Update',
        );
      });
    });
  });

  describe('template', () => {
    it.each`
      webPath                                 | gitlabWebUrl           | webUrl                        | expectedHref                            | expectedTarget
      ${undefined}                            | ${undefined}           | ${`${MOCK_GITLAB_URL}/issue`} | ${`${MOCK_GITLAB_URL}/issue`}           | ${undefined}
      ${undefined}                            | ${undefined}           | ${'https://jira.com/issue'}   | ${'https://jira.com/issue'}             | ${'_blank'}
      ${undefined}                            | ${'/gitlab-org/issue'} | ${'https://jira.com/issue'}   | ${'/gitlab-org/issue'}                  | ${undefined}
      ${'/gitlab-org/gitlab-test/-/issues/1'} | ${undefined}           | ${'https://jira.com/issue'}   | ${'/gitlab-org/gitlab-test/-/issues/1'} | ${undefined}
      ${'/gitlab-org/gitlab-test/-/issues/1'} | ${'/gitlab-org/issue'} | ${undefined}                  | ${'/gitlab-org/gitlab-test/-/issues/1'} | ${undefined}
      ${'/gitlab-org/gitlab-test/-/issues/1'} | ${undefined}           | ${undefined}                  | ${'/gitlab-org/gitlab-test/-/issues/1'} | ${undefined}
    `(
      'renders issuable title correctly when `gitlabWebUrl` is `$gitlabWebUrl`, webUrl is `$webUrl`, and webPath is `$webPath`',
      async ({ webUrl, gitlabWebUrl, webPath, expectedHref, expectedTarget }) => {
        wrapper = createComponent({
          issuable: {
            ...mockIssuable,
            webUrl,
            webPath,
            gitlabWebUrl,
          },
        });

        await nextTick();

        const titleEl = wrapper.findByTestId('issuable-title');

        expect(titleEl.exists()).toBe(true);
        expect(titleEl.findComponent(GlLink).attributes('href')).toBe(expectedHref);
        expect(titleEl.findComponent(GlLink).attributes('target')).toBe(expectedTarget);
        expect(titleEl.findComponent(GlLink).text()).toBe(mockIssuable.title);
      },
    );

    it('renders checkbox when `showCheckbox` prop is true', async () => {
      wrapper = createComponent({
        showCheckbox: true,
      });

      await nextTick();

      expect(wrapper.findComponent(GlFormCheckbox).exists()).toBe(true);
      expect(wrapper.findComponent(GlFormCheckbox).attributes('checked')).not.toBeDefined();

      wrapper.setProps({
        checked: true,
      });

      await nextTick();

      expect(wrapper.findComponent(GlFormCheckbox).attributes('checked')).toBe('true');
    });

    it('renders issuable title with `target` set as "_blank" when issuable.webUrl is external', async () => {
      wrapper = createComponent({
        issuable: {
          ...mockIssuable,
          webUrl: 'http://jira.atlassian.net/browse/IG-1',
        },
      });

      await nextTick();

      expect(
        wrapper.findByTestId('issuable-title').findComponent(GlLink).attributes('target'),
      ).toBe('_blank');
    });

    it('renders issuable confidential icon when issuable is confidential', async () => {
      wrapper = createComponent({
        issuable: {
          ...mockIssuable,
          confidential: true,
        },
      });

      await nextTick();

      const confidentialEl = wrapper.findByTestId('issuable-title').findComponent(GlIcon);

      expect(confidentialEl.exists()).toBe(true);
      expect(confidentialEl.props('name')).toBe('eye-slash');
      expect(confidentialEl.attributes()).toMatchObject({
        title: 'Confidential',
        arialabel: 'Confidential',
      });
    });

    it('renders spam icon when issuable is hidden', () => {
      wrapper = createComponent({ issuable: { ...mockIssuable, hidden: true } });

      const hiddenIcon = wrapper.findComponent(GlIcon);

      expect(hiddenIcon.props('name')).toBe('spam');
      expect(hiddenIcon.attributes()).toMatchObject({
        title: 'This issue is hidden because its author has been banned.',
        arialabel: 'Hidden',
      });
    });

    it('renders task status', () => {
      wrapper = createComponent();

      const taskStatus = wrapper.findByTestId('task-status');
      const expected = `${mockIssuable.taskCompletionStatus.completedCount} of ${mockIssuable.taskCompletionStatus.count} checklist items completed`;

      expect(taskStatus.text()).toBe(expected);
    });

    it('does not renders work item type icon by default', () => {
      wrapper = createComponent();

      expect(findWorkItemTypeIcon().exists()).toBe(false);
    });

    it('renders work item type icon when props passed', () => {
      wrapper = createComponent({ showWorkItemTypeIcon: true });

      expect(findWorkItemTypeIcon().props('workItemType')).toBe(mockIssuable.type);
    });

    it('renders issuable reference', () => {
      wrapper = createComponent();

      const referenceEl = wrapper.findByTestId('issuable-reference');

      expect(referenceEl.exists()).toBe(true);
      expect(referenceEl.text()).toBe(`#${mockIssuable.iid}`);
    });

    it('renders issuable reference via slot', () => {
      wrapper = createComponent({
        issuableSymbol: '#',
        issuable: mockIssuable,
        slots: {
          reference: `
            <b class="js-reference">${mockIssuable.iid}</b>
          `,
        },
      });
      const referenceEl = wrapper.find('.js-reference');

      expect(referenceEl.exists()).toBe(true);
      expect(referenceEl.text()).toBe(`${mockIssuable.iid}`);
    });

    it('renders issuable createdAt info', () => {
      wrapper = createComponent();

      const createdAtEl = wrapper.findByTestId('issuable-created-at');

      expect(createdAtEl.exists()).toBe(true);
      expect(createdAtEl.attributes('title')).toBe(
        localeDateFormat.asDateTimeFull.format(mockIssuable.createdAt),
      );
      expect(createdAtEl.text()).toBe(wrapper.vm.createdAt);
    });

    it('renders issuable author info', () => {
      wrapper = createComponent();

      const authorEl = wrapper.findByTestId('issuable-author');

      expect(authorEl.exists()).toBe(true);
      expect(authorEl.attributes()).toMatchObject({
        'data-user-id': `${wrapper.vm.authorId}`,
        'data-username': mockAuthor.username,
        'data-name': mockAuthor.name,
        'data-avatar-url': mockAuthor.avatarUrl,
        href: mockAuthor.webPath,
      });
      expect(authorEl.text()).toBe(mockAuthor.name);
    });

    it('renders issuable author info via slot', () => {
      wrapper = createComponent({
        issuableSymbol: '#',
        issuable: mockIssuable,
        slots: {
          reference: `
            <span class="js-author">${mockAuthor.name}</span>
          `,
        },
      });
      const authorEl = wrapper.find('.js-author');

      expect(authorEl.exists()).toBe(true);
      expect(authorEl.text()).toBe(mockAuthor.name);
    });

    it('renders issuable external author info via author slot', () => {
      wrapper = createComponent({
        issuableSymbol: '#',
        issuable: { ...mockIssuable, externalAuthor: 'client@example.com' },
      });

      expect(wrapper.findByTestId('external-author').text()).toBe('client@example.com via');
    });

    it('renders timeframe via slot', () => {
      wrapper = createComponent({
        issuableSymbol: '#',
        issuable: mockIssuable,
        slots: {
          timeframe: `
            <b class="js-timeframe">Jan 1, 2020 - Mar 31, 2020</b>
          `,
        },
      });
      const timeframeEl = wrapper.find('.js-timeframe');

      expect(timeframeEl.exists()).toBe(true);
      expect(timeframeEl.text()).toBe('Jan 1, 2020 - Mar 31, 2020');
    });

    it('renders gl-label component for each label present within `issuable` prop', () => {
      wrapper = createComponent();

      const labelsEl = wrapper.findAllComponents(GlLabel);

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

    describe('status', () => {
      it('renders issuable status via slot', () => {
        wrapper = createComponent({
          issuableSymbol: '#',
          issuable: mockIssuable,
          slots: {
            status: `
              <b data-testid="js-status">${mockIssuable.state}</b>
            `,
          },
        });
        const statusEl = wrapper.findByTestId('js-status');

        expect(statusEl.exists()).toBe(true);
        expect(statusEl.text()).toBe(`${mockIssuable.state}`);
      });

      it('renders issuable status as badge', () => {
        const closedMockIssuable = { ...mockIssuable, state: 'closed' };
        wrapper = createComponent({
          issuableSymbol: '#',
          issuable: closedMockIssuable,
          slots: {
            status: closedMockIssuable.state,
          },
        });
        const statusEl = findStatusEl();

        expect(statusEl.findComponent(GlBadge).exists()).toBe(true);
        expect(statusEl.text()).toBe(`${closedMockIssuable.state}`);
      });

      it('renders issuable status without badge if open', () => {
        wrapper = createComponent({
          issuableSymbol: '#',
          issuable: mockIssuable,
          slots: {
            status: mockIssuable.state,
          },
        });

        const statusEl = findStatusEl();

        expect(statusEl.findComponent(GlBadge).exists()).toBe(false);
        expect(statusEl.text()).toBe(`${mockIssuable.state}`);
      });
    });

    it('renders discussions count', () => {
      wrapper = createComponent();

      const discussionsEl = wrapper.findByTestId('issuable-comments');

      expect(discussionsEl.exists()).toBe(true);
      expect(discussionsEl.findComponent(GlLink).attributes()).toMatchObject({
        title: 'Comments',
        href: `${mockIssuable.webUrl}#notes`,
      });
      expect(discussionsEl.findComponent(GlIcon).props('name')).toBe('comments');
      expect(discussionsEl.findComponent(GlLink).text()).toContain('2');
    });

    it('renders issuable-assignees component', () => {
      wrapper = createComponent();

      const assigneesEl = wrapper.findComponent(IssuableAssignees);

      expect(assigneesEl.exists()).toBe(true);
      expect(assigneesEl.props()).toMatchObject({
        assignees: mockIssuable.assignees,
        iconSize: 16,
        maxVisible: 4,
      });
    });

    it('renders issuable updatedAt info', () => {
      wrapper = createComponent();

      const timestampEl = wrapper.findByTestId('issuable-timestamp');

      expect(timestampEl.attributes('title')).toBe(
        localeDateFormat.asDateTimeFull.format(mockIssuable.updatedAt),
      );
      expect(timestampEl.text()).toBe(wrapper.vm.formattedTimestamp);
    });

    describe('when issuable is closed', () => {
      it('renders issuable card with a closed style', () => {
        wrapper = createComponent({
          issuable: { ...mockIssuable, closedAt: '2020-12-10', state: 'closed' },
        });

        expect(wrapper.classes()).toContain('closed');
      });

      it('renders issuable closedAt info and does not render updatedAt info', () => {
        const closedAt = '2022-06-18T11:30:00Z';
        wrapper = createComponent({
          issuable: { ...mockIssuable, closedAt, state: 'closed' },
        });

        const timestampEl = wrapper.findByTestId('issuable-timestamp');

        expect(timestampEl.attributes('title')).toBe(
          localeDateFormat.asDateTimeFull.format(closedAt),
        );
        expect(timestampEl.text()).toBe(wrapper.vm.formattedTimestamp);
      });
    });

    describe('scoped labels', () => {
      describe.each`
        description                                                         | labelPosition | hasScopedLabelsFeature | scoped
        ${'when label is not scoped and there is no scoped_labels feature'} | ${0}          | ${false}               | ${false}
        ${'when label is scoped and there is no scoped_labels feature'}     | ${1}          | ${false}               | ${false}
        ${'when label is not scoped and there is scoped_labels feature'}    | ${0}          | ${true}                | ${false}
        ${'when label is scoped and there is scoped_labels feature'}        | ${1}          | ${true}                | ${true}
      `('$description', ({ hasScopedLabelsFeature, labelPosition, scoped }) => {
        it(`${scoped ? 'renders' : 'does not render'} as scoped label`, () => {
          wrapper = createComponent({ hasScopedLabelsFeature });

          expect(wrapper.findAllComponents(GlLabel).at(labelPosition).props('scoped')).toBe(scoped);
        });
      });
    });
  });

  describe('when preventing redirect on clicking the link', () => {
    it('emits an event on item click', () => {
      const { iid, webUrl } = mockIssuable;

      wrapper = createComponent({
        preventRedirect: true,
      });

      findIssuableTitleLink().vm.$emit('click', new MouseEvent('click'));

      expect(wrapper.emitted('select-issuable')).toEqual([[{ iid, webUrl }]]);
    });

    it('does not apply highlighted class when item is not active', () => {
      wrapper = createComponent({
        preventRedirect: true,
      });

      expect(findIssuableItemWrapper().classes('gl-bg-blue-50')).toBe(false);
    });

    it('applies highlghted class when item is active', () => {
      wrapper = createComponent({
        isActive: true,
        preventRedirect: true,
      });

      expect(findIssuableItemWrapper().classes('gl-bg-blue-50')).toBe(true);
    });
  });
});
