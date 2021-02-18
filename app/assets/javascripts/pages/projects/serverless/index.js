import ServerlessBundle from '~/serverless/serverless_bundle';
import initServerlessSurveyBanner from '~/serverless/survey_banner';

initServerlessSurveyBanner();
new ServerlessBundle(); // eslint-disable-line no-new
