import Tracking from '~/tracking';

export default function trackLearnGitlab(learnGitlabA) {
  Tracking.event('projects:learn_gitlab:index', 'page_init', {
    label: 'learn_gitlab',
    property: learnGitlabA
      ? 'Growth::Conversion::Experiment::LearnGitLabA'
      : 'Growth::Activation::Experiment::LearnGitLabB',
  });
}
