dnsbl_check = Gitlab.config.try(:dnsbl_check)

DNSBLCheck.enabled = dnsbl_check.enabled if dnsbl_check.respond_to?(:enabled)
DNSBLCheck.treshold = dnsbl_check.treshold if dnsbl_check.respond_to?(:treshold)

if dnsbl_check.respond_to?(:lists)
  dnsbl_check.try(:lists).each do |list|
    DNSBLCheck.add_dnsbl(list.domain, list.weight)
  end
end
