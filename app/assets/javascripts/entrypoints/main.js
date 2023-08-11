import '../main';
import { runModules } from '~/run_modules';

const modules = import.meta.glob('../pages/**/index.js');

runModules(modules, '../pages/');
