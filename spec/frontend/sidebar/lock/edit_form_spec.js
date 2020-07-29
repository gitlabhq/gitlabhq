import { shallowMount } from '@vue/test-utils';
import EditForm from '~/sidebar/components/lock/edit_form.vue';
import { ISSUABLE_TYPE_ISSUE, ISSUABLE_TYPE_MR } from './constants';

describe('Edit Form Dropdown', () => {
  let wrapper;
  let issuableType; // Either ISSUABLE_TYPE_ISSUE or ISSUABLE_TYPE_MR
  let issuableDisplayName;

  const setIssuableType = pageType => {
    issuableType = pageType;
    issuableDisplayName = issuableType.replace(/_/g, ' ');
  };

  const findWarningText = () => wrapper.find('[data-testid="warning-text"]');

  const createComponent = ({ props }) => {
    wrapper = shallowMount(EditForm, {
      propsData: {
        isLocked: false,
        issuableDisplayName,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each`
    pageType
    ${ISSUABLE_TYPE_ISSUE} | ${ISSUABLE_TYPE_MR}
  `('In $pageType page', ({ pageType }) => {
    beforeEach(() => {
      setIssuableType(pageType);
    });

    describe.each`
      isLocked | lockStatusText | lockAction  | warningText
      ${false} | ${'unlocked'}  | ${'Lock'}   | ${'Only project members will be able to comment.'}
      ${true}  | ${'locked'}    | ${'Unlock'} | ${'Everyone will be able to comment.'}
    `('when $lockStatusText', ({ isLocked, lockAction, warningText }) => {
      beforeEach(() => {
        createComponent({ props: { isLocked } });
      });

      it(`the appropriate warning text is rendered`, () => {
        expect(findWarningText().text()).toContain(
          `${lockAction} this ${issuableDisplayName}? ${warningText}`,
        );
      });
    });
  });
});
