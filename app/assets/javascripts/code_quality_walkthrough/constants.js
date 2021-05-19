import { s__ } from '~/locale';

export const EXPERIMENT_NAME = 'code_quality_walkthrough';

export const STEPS = {
  commitCiFile: 'commit_ci_file',
  runningPipeline: 'running_pipeline',
  successPipeline: 'success_pipeline',
  failedPipeline: 'failed_pipeline',
  troubleshootJob: 'troubleshoot_job',
};

export const STEPSTATES = {
  [STEPS.commitCiFile]: {
    title: s__("codeQualityWalkthrough|Let's start by creating a new CI file."),
    body: s__(
      'codeQualityWalkthrough|To begin with code quality, we first need to create a new CI file using our code editor. We added a code quality template in the code editor to help you get started %{emojiStart}wink%{emojiEnd} .%{lineBreak}Take some time to review the template, when you are ready, use the %{strongStart}commit changes%{strongEnd} button at the bottom of the page.',
    ),
    buttonText: s__('codeQualityWalkthrough|Got it'),
    placement: 'right',
    offset: 90,
  },
  [STEPS.runningPipeline]: {
    title: s__(
      'codeQualityWalkthrough|Congrats! Your first pipeline is running %{emojiStart}zap%{emojiEnd}',
    ),
    body: s__(
      "codeQualityWalkthrough|Your pipeline can take a few minutes to run. If you enabled email notifications, you'll receive an email with your pipeline status. In the meantime, why don't you get some coffee? You earned it!",
    ),
    buttonText: s__('codeQualityWalkthrough|Got it'),
    offset: 97,
  },
  [STEPS.successPipeline]: {
    title: s__(
      "codeQualityWalkthrough|Well done! You've just automated your code quality review. %{emojiStart}raised_hands%{emojiEnd}",
    ),
    body: s__(
      'codeQualityWalkthrough|A code quality job will now run every time you or your team members commit changes to your project. You can view the results of the code quality job in the job logs.',
    ),
    buttonText: s__('codeQualityWalkthrough|View the logs'),
    offset: 98,
  },
  [STEPS.failedPipeline]: {
    title: s__(
      "codeQualityWalkthrough|Something went wrong. %{emojiStart}thinking%{emojiEnd} Let's fix it.",
    ),
    body: s__(
      "codeQualityWalkthrough|Your job failed. No worries - this happens. Let's view the logs, and see how we can fix it.",
    ),
    buttonText: s__('codeQualityWalkthrough|View the logs'),
    offset: 98,
  },
  [STEPS.troubleshootJob]: {
    title: s__('codeQualityWalkthrough|Troubleshoot your code quality job'),
    body: s__(
      'codeQualityWalkthrough|Not sure how to fix your failed job? We have compiled some tips on how to troubleshoot code quality jobs in the documentation.',
    ),
    buttonText: s__('codeQualityWalkthrough|Read the documentation'),
  },
};

export const PIPELINE_STATUSES = {
  running: 'running',
  successWithWarnings: 'success-with-warnings',
  success: 'success',
  failed: 'failed',
};
