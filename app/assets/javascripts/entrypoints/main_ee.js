import { runModules } from '~/run_modules';

const modules = import.meta.glob('../../../../ee/app/assets/javascripts/pages/**/index.js');

runModules(modules, '../../../../ee/app/assets/javascripts/pages/');
