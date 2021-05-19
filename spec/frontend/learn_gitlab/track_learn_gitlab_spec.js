import { mockTracking } from 'helpers/tracking_helper';
import trackLearnGitlab from '~/learn_gitlab/track_learn_gitlab';

describe('trackTrialUserErrors', () => {
  let spy;

  describe('when an error is present', () => {
    beforeEach(() => {
      spy = mockTracking('projects:learn_gitlab_index', document.body, jest.spyOn);
    });

    it('tracks the error message', () => {
      trackLearnGitlab();

      expect(spy).toHaveBeenCalledWith('projects:learn_gitlab:index', 'page_init', {
        label: 'learn_gitlab',
        property: 'Growth::Activation::Experiment::LearnGitLabB',
      });
    });
  });
});
