import { nextTick } from 'vue';
import { GlIcon } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  issuable1,
  issuable2,
  issuable3,
} from 'jest/issuable/components/related_issuable_mock_data';
import RelatedIssuesBlock from '~/related_issues/components/related_issues_block.vue';
import AddIssuableForm from '~/related_issues/components/add_issuable_form.vue';
import {
  issuableTypesMap,
  linkedIssueTypesMap,
  linkedIssueTypesTextMap,
  PathIdSeparator,
} from '~/related_issues/constants';

describe('RelatedIssuesBlock', () => {
  let wrapper;

  const findToggleButton = () => wrapper.findByTestId('toggle-links');
  const findRelatedIssuesBody = () => wrapper.findByTestId('related-issues-body');
  const findIssueCountBadgeAddButton = () => wrapper.findByTestId('related-issues-plus-button');

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  describe('with defaults', () => {
    beforeEach(() => {
      wrapper = mountExtended(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: issuableTypesMap.ISSUE,
        },
      });
    });

    it.each`
      issuableType | pathIdSeparator          | titleText         | addButtonText
      ${'issue'}   | ${PathIdSeparator.Issue} | ${'Linked items'} | ${'Add a related issue'}
      ${'epic'}    | ${PathIdSeparator.Epic}  | ${'Linked epics'} | ${'Add a related epic'}
    `(
      'displays "$titleText" in the header and "$addButtonText" aria-label for add button when issuableType is set to "$issuableType"',
      ({ issuableType, pathIdSeparator, titleText, addButtonText }) => {
        wrapper = mountExtended(RelatedIssuesBlock, {
          propsData: {
            pathIdSeparator,
            issuableType,
            canAdmin: true,
            helpPath: '/help/user/project/issues/related_issues',
          },
        });

        expect(wrapper.find('.card-title').text()).toContain(titleText);
        expect(findIssueCountBadgeAddButton().attributes('aria-label')).toBe(addButtonText);
      },
    );

    it('unable to add new related issues', () => {
      expect(findIssueCountBadgeAddButton().exists()).toBe(false);
    });

    it('add related issues form is hidden', () => {
      expect(wrapper.find('.js-add-related-issues-form-area').exists()).toBe(false);
    });
  });

  describe('with headerText slot', () => {
    it('displays header text slot data', () => {
      const headerText = '<div>custom header text</div>';

      wrapper = shallowMountExtended(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'issue',
        },
        slots: { 'header-text': headerText },
      });

      expect(wrapper.find('.card-title').html()).toContain(headerText);
    });
  });

  describe('with headerActions slot', () => {
    it('displays header actions slot data', () => {
      const headerActions = '<button data-testid="custom-button">custom button</button>';

      wrapper = shallowMountExtended(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          issuableType: 'issue',
        },
        slots: { 'header-actions': headerActions },
      });

      expect(wrapper.findByTestId('custom-button').html()).toBe(headerActions);
    });
  });

  describe('with isFetching=true', () => {
    beforeEach(() => {
      wrapper = mountExtended(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          isFetching: true,
          issuableType: 'issue',
        },
      });
    });

    it('should show `...` badge count', () => {
      expect(wrapper.vm.badgeLabel).toBe('...');
    });
  });

  describe('with canAddRelatedIssues=true', () => {
    beforeEach(() => {
      wrapper = mountExtended(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          canAdmin: true,
          issuableType: 'issue',
        },
      });
    });

    it('can add new related issues', () => {
      expect(findIssueCountBadgeAddButton().exists()).toBe(true);
    });
  });

  describe('with isFormVisible=true', () => {
    beforeEach(() => {
      wrapper = mountExtended(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          isFormVisible: true,
          issuableType: 'issue',
          autoCompleteEpics: false,
        },
      });
    });

    it('shows add related issues form', () => {
      expect(wrapper.find('.js-add-related-issues-form-area').exists()).toBe(true);
    });

    it('sets `autoCompleteEpics` to false for add-issuable-form', () => {
      expect(wrapper.findComponent(AddIssuableForm).props('autoCompleteEpics')).toBe(false);
    });
  });

  describe('showCategorizedIssues prop', () => {
    const issueList = () => wrapper.findAll('.js-related-issues-token-list-item');
    const categorizedHeadings = () => wrapper.findAll('h4');
    const headingTextAt = (index) => categorizedHeadings().at(index).text();
    const mountComponent = (showCategorizedIssues) => {
      wrapper = mountExtended(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          relatedIssues: [issuable1, issuable2, issuable3],
          issuableType: 'issue',
          showCategorizedIssues,
        },
      });
    };

    describe('when showCategorizedIssues=true', () => {
      beforeEach(() => mountComponent(true));

      it('should render issue tokens items', () => {
        expect(issueList()).toHaveLength(3);
      });

      it('shows "Blocks" heading', () => {
        const blocks = linkedIssueTypesTextMap[linkedIssueTypesMap.BLOCKS];

        expect(headingTextAt(0)).toBe(blocks);
      });

      it('shows "Is blocked by" heading', () => {
        const isBlockedBy = linkedIssueTypesTextMap[linkedIssueTypesMap.IS_BLOCKED_BY];

        expect(headingTextAt(1)).toBe(isBlockedBy);
      });

      it('shows "Relates to" heading', () => {
        const relatesTo = linkedIssueTypesTextMap[linkedIssueTypesMap.RELATES_TO];

        expect(headingTextAt(2)).toBe(relatesTo);
      });
    });

    describe('when showCategorizedIssues=false', () => {
      it('should render issues as a flat list with no header', () => {
        mountComponent(false);

        expect(issueList()).toHaveLength(3);
        expect(categorizedHeadings()).toHaveLength(0);
      });
    });
  });

  describe('renders correct icon when', () => {
    [
      {
        icon: 'issues',
        issuableType: 'issue',
      },
      {
        icon: 'epic',
        issuableType: 'epic',
      },
    ].forEach(({ issuableType, icon }) => {
      it(`issuableType=${issuableType} is passed`, () => {
        wrapper = shallowMountExtended(RelatedIssuesBlock, {
          propsData: {
            pathIdSeparator: PathIdSeparator.Issue,
            issuableType,
          },
        });

        const iconComponent = wrapper.findComponent(GlIcon);
        expect(iconComponent.exists()).toBe(true);
        expect(iconComponent.props('name')).toBe(icon);
      });
    });
  });

  describe('toggle', () => {
    beforeEach(() => {
      wrapper = shallowMountExtended(RelatedIssuesBlock, {
        propsData: {
          pathIdSeparator: PathIdSeparator.Issue,
          relatedIssues: [issuable1, issuable2, issuable3],
          issuableType: issuableTypesMap.ISSUE,
        },
      });
    });

    it('is expanded by default', () => {
      expect(findToggleButton().props('icon')).toBe('chevron-lg-up');
      expect(findToggleButton().props('disabled')).toBe(false);
      expect(findRelatedIssuesBody().exists()).toBe(true);
    });

    it('expands on click toggle button', async () => {
      findToggleButton().vm.$emit('click');
      await nextTick();

      expect(findToggleButton().props('icon')).toBe('chevron-lg-down');
      expect(findRelatedIssuesBody().exists()).toBe(false);
    });
  });

  describe('empty state', () => {
    it.each`
      issuableType  | pathIdSeparator          | showCategorizedIssues | emptyText                                                                                 | helpLinkText
      ${'issue'}    | ${PathIdSeparator.Issue} | ${false}              | ${"Link issues together to show that they're related."}                                   | ${'Learn more about linking issues'}
      ${'issue'}    | ${PathIdSeparator.Issue} | ${true}               | ${"Link issues together to show that they're related or that one is blocking others."}    | ${'Learn more about linking issues'}
      ${'incident'} | ${PathIdSeparator.Issue} | ${false}              | ${"Link incidents together to show that they're related."}                                | ${'Learn more about linking issues and incidents'}
      ${'incident'} | ${PathIdSeparator.Issue} | ${true}               | ${"Link incidents together to show that they're related or that one is blocking others."} | ${'Learn more about linking issues and incidents'}
      ${'epic'}     | ${PathIdSeparator.Epic}  | ${true}               | ${"Link epics together to show that they're related or that one is blocking others."}     | ${'Learn more about linking epics'}
    `(
      'displays "$emptyText" in the body and "$helpLinkText" aria-label for help link',
      ({ issuableType, pathIdSeparator, showCategorizedIssues, emptyText, helpLinkText }) => {
        wrapper = mountExtended(RelatedIssuesBlock, {
          propsData: {
            pathIdSeparator,
            issuableType,
            canAdmin: true,
            helpPath: '/help/user/project/issues/related_issues',
            showCategorizedIssues,
          },
        });

        expect(wrapper.findByTestId('related-issues-body').text()).toContain(emptyText);
        expect(wrapper.findByTestId('help-link').attributes('aria-label')).toBe(helpLinkText);
      },
    );
  });
});
