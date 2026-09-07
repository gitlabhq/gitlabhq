const formatChain = (chain) =>
  chain.map((step) => `          ${step.infected ? 'V3' : 'V2'}  ${step.file}`).join('\n');

export function formatDuplicatedModulesReport(findings) {
  const pages = new Set(findings.map((finding) => finding.page));
  const modules = new Set(findings.map((finding) => finding.module));
  const lines = [
    '',
    `[vue3-infection-scanner] Duplicated modules detected: ` +
      `${modules.size} module(s) on ${pages.size} page state(s), ` +
      `${findings.length} finding(s).`,
    '',
  ];

  let currentPage = null;
  for (const finding of findings) {
    if (finding.page !== currentPage) {
      currentPage = finding.page;
      lines.push(`  ${finding.page}`);
      finding.seeds.forEach((seed, index) => {
        lines.push(`    ${index === 0 ? 'roots:' : '      '} ${seed}`);
      });
      lines.push('');
    }
    lines.push(`    ${finding.module}`);
    lines.push(`       holds: ${finding.singletons.join(', ')}`);
    lines.push(`       sink:  ${finding.sink ?? '(none: this copy has no Vue 3 ancestor)'}`);
    lines.push(formatChain(finding.chain));
    lines.push('');
  }

  lines.push('  Add each sink above to INFECTION_FORCELIST, or see');
  lines.push('  doc/development/fe_guide/vue3_migration.md#module-scope-singletons');
  lines.push('');

  return lines.join('\n');
}
