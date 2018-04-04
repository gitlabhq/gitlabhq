module EE
  module LdapHelpers
    def proxy(adapter, provider = 'ldapmain')
      EE::Gitlab::Auth::LDAP::Sync::Proxy.new(provider, adapter)
    end

    # Stub an LDAP group search and provide the return entry. Specify `nil` for
    # `entry` to simulate when an LDAP group is not found
    #
    # Example:
    #  adapter = ::Gitlab::Auth::LDAP::Adapter.new('ldapmain', double(:ldap))
    #  ldap_group1 = ldap_group_entry('uid=user,ou=users,dc=example,dc=com')
    #
    #  stub_ldap_group_find_by_cn('ldap_group1', ldap_group1, adapter)
    def stub_ldap_group_find_by_cn(cn, entry, adapter = nil)
      if entry.present?
        return_value = EE::Gitlab::Auth::LDAP::Group.new(entry, adapter)
      end

      allow(EE::Gitlab::Auth::LDAP::Group)
        .to receive(:find_by_cn)
          .with(cn, kind_of(::Gitlab::Auth::LDAP::Adapter)).and_return(return_value)
    end

    def unstub_ldap_group_find_by_cn
      allow(EE::Gitlab::Auth::LDAP::Group)
        .to receive(:find_by_cn).and_call_original
    end

    # Create an LDAP group entry with any number of members. By default, creates
    # a groupOfNames style entry. Change the style by specifying the object class
    # and member attribute name. The last example below shows how to specify a
    # posixGroup (Apple Open Directory) entry. `members` can be nil to create
    # an empty group.
    #
    # Example:
    #   ldap_group_entry('uid=user,ou=users,dc=example,dc=com')
    #
    #   ldap_group_entry(
    #     'uid=user1,ou=users,dc=example,dc=com',
    #     'uid=user2,ou=users,dc=example,dc=com'
    #   )
    #
    #   ldap_group_entry(
    #     [ 'user1', 'user2' ],
    #     cn: 'my_group'
    #     objectclass: 'posixGroup',
    #     member_attr: 'memberUid'
    #   )
    def ldap_group_entry(
      members,
      cn: 'ldap_group1',
      objectclass: 'groupOfNames',
      member_attr: 'uniqueMember',
      member_of: nil
    )
      entry = Net::LDAP::Entry.from_single_ldif_string(<<-EOS.strip_heredoc)
        dn: cn=#{cn},ou=groups,dc=example,dc=com
        cn: #{cn}
        description: LDAP Group #{cn}
        objectclass: top
        objectclass: #{objectclass}
      EOS

      entry['memberOf'] = member_of if member_of
      members = [members].flatten
      entry[member_attr] = members if members.any?
      entry
    end

    # To simulate Active Directory ranged member retrieval. Create an LDAP
    # group entry with any number of members in a given range. A '*' signifies
    # the end of the 'pages' has been reached.
    #
    # Example:
    #   ldap_group_entry_with_member_range(
    #     [ 'user1', 'user2' ],
    #     cn: 'my_group',
    #     range_start: '0',
    #     range_end: '*'
    #   )
    def ldap_group_entry_with_member_range(
      members_in_range,
      cn: 'ldap_group1',
      range_start: '0',
      range_end: '*'
    )
      entry = Net::LDAP::Entry.from_single_ldif_string(<<-EOS.strip_heredoc)
        dn: cn=#{cn},ou=groups,dc=example,dc=com
        cn: #{cn}
        description: LDAP Group #{cn}
      EOS

      members_in_range = [members_in_range].flatten
      entry["member;range=#{range_start}-#{range_end}"] = members_in_range
      entry
    end

    # Stub Active Directory range member retrieval.
    #
    # Example:
    #  adapter = ::Gitlab::Auth::LDAP::Adapter.new('ldapmain', double(:ldap))
    #  group_entry_page1 = ldap_group_entry_with_member_range(
    #    [user_dn('user1'), user_dn('user2'), user_dn('user3')],
    #    range_start: '0',
    #    range_end: '2'
    #  )
    #  group_entry_page2 = ldap_group_entry_with_member_range(
    #    [user_dn('user4'), user_dn('user5'), user_dn('user6')],
    #    range_start: '3',
    #    range_end: '*'
    #  )
    #  group = EE::Gitlab::Auth::LDAP::Group.new(group_entry_page1, adapter)
    #
    #  stub_ldap_adapter_group_members_in_range(group_entry_page2, adapter, range_start: '3')
    def stub_ldap_adapter_group_members_in_range(
      entry,
      adapter = ldap_adapter,
      range_start: '0'
    )
      allow(adapter).to receive(:group_members_in_range)
        .with(entry.dn, range_start.to_i).and_return(entry)
    end

    def stub_ldap_adapter_nested_groups(parent_dn, entries = [], adapter = ldap_adapter)
      groups = entries.map { |entry| EE::Gitlab::Auth::LDAP::Group.new(entry, adapter) }

      allow(adapter).to receive(:nested_groups).with(parent_dn).and_return(groups)
    end
  end
end
