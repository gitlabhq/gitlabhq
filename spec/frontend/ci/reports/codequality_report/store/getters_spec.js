import createStore from '~/ci/reports/codequality_report/store';
import * as getters from '~/ci/reports/codequality_report/store/getters';
import { LOADING, ERROR, SUCCESS, STATUS_NOT_FOUND } from '~/ci/reports/constants';

describe('Codequality reports store getters', () => {
  let localState;
  let localStore;

  beforeEach(() => {
    localStore = createStore();
    localState = localStore.state;
  });

  describe('hasCodequalityIssues', () => {
    describe('when there are issues', () => {
      it('returns true', () => {
        localState.newIssues = [{ reason: 'repetitive code' }];
        localState.resolvedIssues = [];

        expect(getters.hasCodequalityIssues(localState)).toEqual(true);

        localState.newIssues = [];
        localState.resolvedIssues = [{ reason: 'repetitive code' }];

        expect(getters.hasCodequalityIssues(localState)).toEqual(true);
      });
    });

    describe('when there are no issues', () => {
      it('returns false when there are no issues', () => {
        expect(getters.hasCodequalityIssues(localState)).toEqual(false);
      });
    });
  });

  describe('codequalityStatus', () => {
    describe('when loading', () => {
      it('returns loading status', () => {
        localState.isLoading = true;

        expect(getters.codequalityStatus(localState)).toEqual(LOADING);
      });
    });

    describe('on error', () => {
      it('returns error status', () => {
        localState.hasError = true;

        expect(getters.codequalityStatus(localState)).toEqual(ERROR);
      });
    });

    describe('when successfully loaded', () => {
      it('returns error status', () => {
        expect(getters.codequalityStatus(localState)).toEqual(SUCCESS);
      });
    });
  });

  describe('codequalityText', () => {
    it.each`
      resolvedIssues | newIssues | expectedText
      ${0}           | ${0}      | ${'No changes to code quality'}
      ${0}           | ${1}      | ${'Code quality degraded due to 1 new issue'}
      ${2}           | ${0}      | ${'Code quality improved due to 2 resolved issues'}
      ${1}           | ${2}      | ${'Code quality scanning detected 3 changes in merged results'}
    `(
      'returns a summary containing $resolvedIssues resolved issues and $newIssues new issues',
      ({ newIssues, resolvedIssues, expectedText }) => {
        localState.newIssues = new Array(newIssues).fill({ reason: 'Repetitive code' });
        localState.resolvedIssues = new Array(resolvedIssues).fill({ reason: 'Repetitive code' });

        expect(getters.codequalityText(localState)).toEqual(expectedText);
      },
    );
  });

  describe('codequalityPopover', () => {
    describe('when base report is not available', () => {
      it('returns a popover with a documentation link', () => {
        localState.status = STATUS_NOT_FOUND;
        localState.helpPath = 'codequality_help.html';

        expect(getters.codequalityPopover(localState).title).toEqual(
          'Base pipeline codequality artifact not found',
        );
        expect(getters.codequalityPopover(localState).content).toContain(
          'Learn more about codequality reports',
          'href="codequality_help.html"',
        );
      });
    });
  });
});
