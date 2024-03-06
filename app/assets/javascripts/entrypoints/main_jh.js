import { runModules } from '~/run_modules';

const modules = import.meta.glob('../../../../jh/app/assets/javascripts/pages/**/index.js');

runModules(modules, 'JH');
